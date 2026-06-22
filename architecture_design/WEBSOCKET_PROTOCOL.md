# Game Sync Protocol & WebSocket Sequence (v2)

## 0. Lobby & Room Management Protocol
`/ws/game/{room_id}` 연결 이전, 로비 화면은 별도 엔드포인트 `/ws/lobby`에 연결하여 방 목록과 입장/대기 상태를 동기화함. 메시지 envelope은 [3. Message Envelope Design](#3-message-envelope-design)과 동일한 `{ type, payload, seq }` 구조를 따름. (Backend Epic #2 미구현 상태이며, 이 절은 FE 작업(P3-09)을 위해 선제적으로 정의한 계약임 — 백엔드 구현 시 본 스펙을 기준으로 삼을 것)

### 0.1. Room Object
```json
{
  "id": "room-uuid",
  "host": { "userId": "uuid", "nickname": "host_nick", "characterId": "magician", "ready": false },
  "guest": { "userId": "uuid", "nickname": "guest_nick", "characterId": "knight", "ready": false } | null,
  "status": "WAITING | IN_GAME",
  "createdAt": "2026-06-22T10:00:00Z"
}
```

### 0.2. Client → Server Messages
| Type | Payload | Description |
| :--- | :--- | :--- |
| `LIST_ROOMS` | `{}` | 현재 방 목록 스냅샷 요청 (연결 시 자동 수신도 됨) |
| `CREATE_ROOM` | `{ characterId }` | 새 방 생성, 본인이 host가 됨 |
| `JOIN_ROOM` | `{ roomId, characterId }` | 대기중인 방에 guest로 입장 |
| `LEAVE_ROOM` | `{ roomId }` | 방 퇴장 (host 퇴장 시 방 폭파) |
| `SET_READY` | `{ roomId, ready }` | 준비 완료/취소 토글 |

### 0.3. Server → Client Messages
| Type | Payload | Description |
| :--- | :--- | :--- |
| `ROOM_LIST` | `{ rooms: Room[] }` | 전체 방 목록 (연결 시 + 변경 발생 시 broadcast) |
| `ROOM_UPDATED` | `{ room: Room }` | 특정 방의 상태 변경 (입장/캐릭터 선택/준비 상태) |
| `ROOM_CLOSED` | `{ roomId }` | 방 삭제 (host 퇴장 등) |
| `GAME_START` | `{ roomId }` | host/guest 모두 ready 시 발송, 클라이언트는 `/ws/game/{roomId}`로 전환 |
| `ACTION_REJECTED` | `{ message }` | 잘못된 요청(예: 이미 가득 찬 방 입장 시도) |

### 0.4. Sequence
```mermaid
sequenceDiagram
    participant C1 as Client A (Host)
    participant C2 as Client B (Guest)
    participant S as Server (Lobby)

    C1->>S: CONNECT /ws/lobby
    S->>C1: ROOM_LIST
    C1->>S: CREATE_ROOM (characterId)
    S->>C1: ROOM_UPDATED (room, host set)
    S-->>C2: ROOM_LIST (broadcast)
    C2->>S: JOIN_ROOM (roomId, characterId)
    S->>C1: ROOM_UPDATED (guest joined)
    S->>C2: ROOM_UPDATED (guest joined)
    C1->>S: SET_READY (true)
    C2->>S: SET_READY (true)
    S->>C1: GAME_START (roomId)
    S->>C2: GAME_START (roomId)
```

## 1. Game Start Sequence
서버와 클라이언트 간의 초기 연결 및 동기화 프로세스입니다.

\`\`\`mermaid
sequenceDiagram
    participant C1 as Client A (Host)
    participant C2 as Client B (Guest)
    participant S as Server (Channels)
    participant R as Redis

    C1->>S: CONNECT /ws/game/{room_id}
    C2->>S: CONNECT /ws/game/{room_id}
    S->>R: CHECK_ROOM_READY
    R-->>S: READY
    S->>C1: MSG: GAME_START (Initial Deck Info)
    S->>C2: MSG: GAME_START (Initial Deck Info)
    S->>C1: MSG: PHASE_UPDATE (DRAW)
    S->>C2: MSG: PHASE_UPDATE (DRAW)
\`\`\`

## 2. In-Game Phase Sync (Move Phase)
이동 페이즈에서의 동기화 예시입니다.

\`\`\`mermaid
sequenceDiagram
    participant C1 as Client A
    participant S as Server
    participant C2 as Client B

    C1->>S: SEND_ACTION (MOVE_CARDS: [4, 7])
    S->>S: VALIDATE_OWNERSHIP & RULES
    Note over S: Client B is still thinking...
    C2->>S: SEND_ACTION (MOVE_CARDS: [2])
    S->>S: COMPUTE_RESULT (Distance, Initiative)
    S->>C1: BROADCAST: MOVE_RESULT (New Dist: 1, Init: A)
    S->>C2: BROADCAST: MOVE_RESULT (New Dist: 1, Init: A)
    S->>C1: BROADCAST: PHASE_UPDATE (ATTACK)
    S->>C2: BROADCAST: PHASE_UPDATE (ATTACK)
\`\`\`

## 3. Message Envelope Design
모든 WebSocket 메시지는 다음 구조를 따름.

\`\`\`json
{
  "type": "ACTION_REJECTED, STATE_UPDATE, NOTIFICATION",
  "payload": { ... },
  "seq": 102  // 클라이언트 측 메시지 순서 보장용 시퀀스 번호
}
\`\`\`

## 4. Reconnection Logic
- **Heartbeat**: 5초마다 PING/PONG 체크.
- **State Recovery**: 재접속 시 서버는 Redis에 보관된 최신 \`room_state\` 전체를 다시 전송함.
- **Grace Period**: 연결 유실 후 15초 내 미복구 시 몰수패 처리.

- **Cluster & Checkpoint-aware Recovery**:
  - 클러스터 환경에서는 Redis 접근 중 `MOVED`/`ASK` 응답이나 일시적 접근 불가가 발생할 수 있으므로 서버는 클러스터-aware 클라이언트로 토폴로지 갱신과 자동 재시도를 수행합니다.
  - 재접속 시 서버가 Redis에서 `room:{id}:state` 키를 찾지 못하거나 접근 오류가 발생하면 다음 순서로 복구를 시도합니다:
    1. 클러스터 클라이언트에서 `MOVED`/`ASK`를 처리하여 재요청(토폴로지 갱신 포함)을 시도합니다.
    2. 재시도 실패 시 PostgreSQL에 저장된 최신 체크포인트(`game_checkpoints` 테이블)를 가져와 세션 상태를 복원합니다.
    3. 체크포인트와 함께 보관된 액션 로그(가능한 경우 Redis Streams 또는 영속 로그)를 재생하여 최신 상태로 보완합니다.
  - 복구 시도는 지수 백오프(예: 초기 100ms, 최대 2s)와 최대 재시도 횟수(예: 5회)를 적용합니다. 모든 시도가 실패하면 서버는 사용자에게 복구 불가 알림을 보내거나 세션을 안전하게 종료합니다.
  - 복구 과정은 메트릭으로 수집합니다: 복구 성공률, 체크포인트 활용률, 재시도 횟수, 복구 지연 등을 모니터링합니다.

---

## 5. Chat Namespace (`/chat`)

### 5.1 연결 인증

Chat WebSocket은 `/chat` namespace에서 동작합니다. 연결 시 반드시 JWT 토큰을 전달해야 합니다.

```json
// 핸드셰이크 auth payload
{
  "auth": {
    "token": "Bearer <JWT_ACCESS_TOKEN>"
  }
}
```

또는 쿼리 파라미터로 전달:

```
/chat?token=Bearer <JWT_ACCESS_TOKEN>
```

토큰이 없거나 유효하지 않으면 서버가 즉시 소켓을 disconnect합니다.

### 5.2 이벤트 정의

#### 클라이언트 → 서버: `send_message`

```json
{
  "content": "안녕하세요!",
  "roomId": "optional-room-id",
  "type": "NORMAL"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `content` | string | ✓ | 메시지 내용 (비어있을 수 없음) |
| `roomId` | string | - | 특정 채팅방 ID (없으면 글로벌 채널) |
| `type` | `"NORMAL"` \| `"INVITE"` | - | 메시지 유형 (기본값: `"NORMAL"`) |

#### 서버 → 전체 클라이언트: `receive_message`

```json
{
  "id": "uuid-v4",
  "content": "안녕하세요!",
  "roomId": null,
  "type": "NORMAL",
  "createdAt": "2026-06-22T12:00:00.000Z",
  "sender": {
    "id": "user-uuid",
    "nickname": "player1"
  }
}
```

### 5.3 연결 시퀀스

```mermaid
sequenceDiagram
    participant C as Client
    participant G as ChatGateway
    participant J as JwtService
    participant DB as PostgreSQL

    C->>G: CONNECT /chat (auth.token)
    G->>J: verifyAsync(token)
    alt 유효하지 않은 토큰
        J-->>G: throw error
        G->>C: disconnect()
    else 유효한 토큰
        J-->>G: { sub: userId, ... }
        G->>DB: findUser(userId)
        DB-->>G: User entity
        G->>G: client.data.user = user
        G-->>C: connected
    end
```

### 5.4 메시지 흐름

```mermaid
sequenceDiagram
    participant C1 as Client (Sender)
    participant G as ChatGateway
    participant S as ChatService
    participant DB as PostgreSQL
    participant All as All Clients

    C1->>G: send_message { content, roomId, type }
    G->>S: saveMessage(senderId, content, roomId, type)
    S->>DB: INSERT INTO chat_messages
    DB-->>S: ChatMessage entity
    S-->>G: saved message
    G->>All: receive_message { id, content, sender, createdAt, ... }
```

### 5.5 REST 보완 API

채팅 히스토리는 WebSocket 외 REST API로도 조회 가능합니다 (JWT 인증 필요).

```
GET /api/chat/history
```

→ 최근 50개 메시지를 `createdAt` 오름차순으로 반환. 상세 스펙은 `API_SPECIFICATION.md` 참조.

---

## 6. Game Namespace (`/game`)

### 6.1 연결 인증

Game WebSocket은 `/game` namespace에서 동작하며, 인증 방식은 `/chat`(5.1)과 동일한 컨벤션을 따릅니다 — 핸드셰이크 `auth.token` 또는 `?token=` 쿼리 파라미터로 `Bearer <JWT_ACCESS_TOKEN>` 전달. 토큰이 없거나 유효하지 않으면 서버가 즉시 소켓을 disconnect합니다.

두 네임스페이스의 공통 토큰 추출 로직은 `src/common/websocket/ws-jwt.util.ts`의 `extractWsToken()`을 공유합니다 (현재 `/game`에서 사용 중이며, `/chat`도 동일 컨벤션이라 추후 이 유틸로 통합 가능).

### 6.2 연결 시퀀스

```mermaid
sequenceDiagram
    participant C as Client
    participant G as GameGateway
    participant J as JwtService
    participant DB as PostgreSQL

    C->>G: CONNECT /game (auth.token)
    G->>J: verify(token)
    alt 유효하지 않은 토큰 / 토큰 없음
        J-->>G: throw error
        G->>C: disconnect()
    else 유효한 토큰
        J-->>G: { sub: userId, ... }
        G->>DB: findOne(userId)
        DB-->>G: User entity
        G->>G: client.data.user = user
        G-->>C: connected
    end
```

### 6.3 현재 구현 범위

이 이슈(P4-01)는 게이트웨이 연결/인증/로깅만 다룹니다. 방 입장, 카드 제출, 페이즈 브로드캐스트 등 실제 게임 이벤트는 후속 이슈(P4-03~05, wave 3)에서 이 네임스페이스에 `@SubscribeMessage` 핸들러로 추가될 예정입니다 — 이벤트 스펙은 그때 이 섹션에 추가합니다.

게임 룸/State Machine 데이터 모델(`Character`/`Card`/`MatchHistory` 엔티티, `GameModule`)은 별도 PR([#40](https://github.com/222transcendence/transcendence_backend/pull/40), [#47](https://github.com/222transcendence/transcendence_backend/pull/47))에서 진행 중이며, 두 PR이 동일 파일을 서로 다르게 구현해 충돌 중이라 이 게이트웨이는 의도적으로 그쪽 모듈/엔티티에 의존하지 않게 만들었습니다.
