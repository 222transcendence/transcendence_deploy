# API Specification v3 (Enterprise Standard)

## 0. 경로 규칙 — `/api/` 접두사 통일

모든 REST 엔드포인트는 `/api/` 접두사로 시작한다 (`/api/auth/*`, `/api/users/*`, `/api/friends/*`,
`/api/chat/*`, `/api/game/*`). nginx의 `location /api` 블록이 이 접두사 기준으로 백엔드에 프록시하므로,
컨트롤러가 접두사를 빠뜨리면 프론트가 문서대로 호출해도 실제로는 404가 난다.

새 컨트롤러를 추가할 때는 반드시 `api/` 접두사를 포함할 것.

## 1. Request/Response Envelope
모든 응답은 일관된 형식을 유지함.

\`\`\`json
{
  "timestamp": "2026-05-12T10:00:00Z",
  "status": 200,
  "data": { ... },
  "error": null
}
```

## 2. API Endpoint Details (Highlight)

### [POST] /api/users/me/avatar
- **Description**: 로그인한 사용자의 아바타 이미지를 업로드하고 프로필에 반영.
- **Auth**: `Authorization: Bearer <token>` 필수 (JwtAuthGuard).
- **Request**: `multipart/form-data`, 필드명 `avatar` (단일 파일).
- **허용 형식**: `image/jpeg`, `image/png`, `image/webp`, 최대 2MB.
- **저장 방식**: 서버 로컬 디스크 (`uploads/avatars/`), 파일명은 UUID로 재생성. `/uploads` 경로로 정적 서빙됨.
- **Response**: 비밀번호를 제외한 갱신된 User 객체 (`avatar` 필드에 새 URL 포함).
- **Error Codes**:
    - `400`: 파일 누락 또는 허용되지 않은 형식/용량 초과
    - `401`: 인증 토큰 없음/만료

### Authentication APIs

#### [POST] /api/auth/signup
- **Description**: 이메일과 패스워드로 신규 사용자 회원가입을 처리합니다.
- **Request Body**:
    ```json
    {
      "email": "user@example.com",
      "nickname": "new_user",
      "password": "securepassword123"
    }
    ```
- **Response (Success 201)**:
    ```json
    {
      "timestamp": "2026-05-29T14:00:00Z",
      "status": 201,
      "data": {
        "id": "uuid-v4-string",
        "email": "user@example.com",
        "nickname": "new_user",
        "avatar": "default_avatar.png",
        "status": "OFFLINE",
        "wins": 0,
        "losses": 0,
        "createdAt": "2026-05-29T14:00:00Z",
        "updatedAt": "2026-05-29T14:00:00Z"
      },
      "error": null
    }
    ```
- **Error Codes**:
    - `400 Bad Request` (E_BAD_REQUEST): 입력 데이터 유효성 검사 실패 (짧은 비밀번호, 이메일 형식 등)
    - `409 Conflict` (E_CONFLICT): 이미 가입된 이메일 또는 사용 중인 닉네임

#### [POST] /api/auth/login
- **Description**: 사용자 자격 증명을 검증하고 Access/Refresh Token을 발급합니다.
- **Request Body**:
    ```json
    {
      "email": "user@example.com",
      "password": "securepassword123"
    }
    ```
- **Response (Success 200)**:
    ```json
    {
      "timestamp": "2026-05-29T14:00:00Z",
      "status": 200,
      "data": {
        "accessToken": "jwt-access-token-string",
        "refreshToken": "jwt-refresh-token-string",
        "user": {
          "id": "uuid-v4-string",
          "email": "user@example.com",
          "nickname": "new_user",
          "avatar": "default_avatar.png",
          "status": "ONLINE"
        }
      },
      "error": null
    }
    ```
- **Error Codes**:
    - `401 Unauthorized` (E1001): 잘못된 비밀번호 또는 가입되지 않은 이메일

#### [POST] /api/auth/refresh
- **Description**: 만료된 Access Token을 갱신합니다.
- **Request Body**:
    ```json
    {
      "refreshToken": "jwt-refresh-token-string"
    }
    ```
- **Response (Success 200)**:
    ```json
    {
      "timestamp": "2026-05-29T14:00:00Z",
      "status": 200,
      "data": {
        "accessToken": "new-jwt-access-token-string"
      },
      "error": null
    }
    ```
- **Error Codes**:
    - `401 Unauthorized` (E1001): 유효하지 않거나 탈취된/로그아웃된 Refresh Token

#### [POST] /api/auth/logout
- **Description**: 로그인 세션을 종료하고 Refresh Token을 무효화합니다 (JWT Bearer Token 필요).
- **Headers**: `Authorization: Bearer <accessToken>`
- **Response (Success 200)**:
    ```json
    {
      "timestamp": "2026-05-29T14:00:00Z",
      "status": 200,
      "data": {
        "success": true
      },
      "error": null
    }
    ```

#### [GET] /api/auth/42
- **Description**: 42 OAuth 2.0 인증 페이지로 리디렉트합니다.
- **Auth**: 없음 (public)
- **Response**: 302 Redirect → `https://api.intra.42.fr/oauth/authorize?...`

#### [GET] /api/auth/42/callback
- **Description**: 42 OAuth 콜백 엔드포인트. 인증 성공 시 JWT 토큰을 발급합니다.
- **Auth**: 없음 (public, passport-42 처리)
- **Query Params**: `code` (42 인가 코드), `state`
- **Response (Success 201)**:
    ```json
    {
      "timestamp": "2026-05-29T14:00:00Z",
      "status": 201,
      "data": {
        "accessToken": "<JWT_ACCESS_TOKEN>",
        "refreshToken": "<JWT_REFRESH_TOKEN>",
        "user": {
          "id": "uuid",
          "email": "user@student.42gyeongsan.kr",
          "nickname": "user42",
          "avatar": "https://cdn.intra.42.fr/...",
          "status": "ONLINE"
        }
      },
      "error": null
    }
    ```
- **Errors**:
    - `401 Unauthorized`: 유효하지 않은 42 인가 코드

### Chat APIs

All endpoints below are prefixed with `/api/chat` and require **JWT Bearer Token** (`Authorization: Bearer <accessToken>`).

#### [GET] /api/chat/history
- **Description**: 최근 채팅 메시지 50개를 시간 순(오래된 것 먼저)으로 반환합니다.
- **Headers**: `Authorization: Bearer <accessToken>`
- **Response (Success 200)**:
    ```json
    {
      "timestamp": "2026-06-22T12:00:00Z",
      "status": 200,
      "data": [
        {
          "id": "uuid-v4-string",
          "sender": {
            "id": "uuid-v4-string",
            "nickname": "alice",
            "avatar": "avatars/alice.png"
          },
          "content": "Hello, World!",
          "roomId": null,
          "type": "NORMAL",
          "createdAt": "2026-06-22T11:59:00Z"
        }
      ],
      "error": null
    }
    ```
- **Message Types**: `NORMAL` (일반 채팅), `INVITE` (게임 초대)
- **Access**: Private (JWT 필요)

---

### Game APIs

> 게임(산성비) 방 생성/입장/매치 진행은 REST가 아니라 WebSocket으로 처리한다 — 로비 프로토콜은
> `WEBSOCKET_PROTOCOL.md` §0(`/ws/lobby`), 실제 대전 이벤트는 §6(`/game` 네임스페이스) 참고. 아래는
> REST로 남아있는 통계/리더보드 API만 다룬다.

### [GET] /api/users/me
- **Description**: 로그인한 사용자 본인의 전체 프로필 정보를 가져옴. (비밀번호 제외)
- **Authentication**: JWT 필수
- **Success Response (200 OK)**:
    \`\`\`json
    {
      "timestamp": "2026-05-29T10:00:00Z",
      "status": 200,
      "data": {
        "id": "uuid-string",
        "email": "user@example.com",
        "nickname": "my_nickname",
        "avatar": "default_avatar.png",
        "status": "ONLINE",
        "wins": 10,
        "losses": 5,
        "createdAt": "2026-05-29T00:00:00Z",
        "updatedAt": "2026-05-29T00:00:00Z"
      },
      "error": null
    }
    \`\`\`

### [GET] /api/users/{id}
- **Description**: 특정 사용자 ID에 해당하는 타인의 프로필 정보를 가져옴. 민감한 정보(이메일, 비밀번호)는 제외하고 공개 가능한 데이터만 반환함.
- **Authentication**: JWT 필수
- **Success Response (200 OK)**:
    \`\`\`json
    {
      "timestamp": "2026-05-29T10:00:00Z",
      "status": 200,
      "data": {
        "id": "uuid-string",
        "nickname": "target_nickname",
        "avatar": "default_avatar.png",
        "status": "ONLINE",
        "wins": 12,
        "losses": 8,
        "createdAt": "2026-05-29T00:00:00Z",
        "updatedAt": "2026-05-29T00:00:00Z"
      },
      "error": null
    }
    \`\`\`
- **Error Codes**:
    - \`404\`: 존재하지 않는 사용자 ID

### [PATCH] /api/users/me
- **Description**: 로그인한 본인의 \`nickname\` 또는 \`avatar\`를 수정함. 닉네임 수정 시 중복 검사를 거침.
- **Authentication**: JWT 필수
- **Request Body**:
    \`\`\`json
    {
      "nickname": "new_nickname",
      "avatar": "new_avatar.png"
    }
    \`\`\`
- **Success Response (200 OK)**:
    \`\`\`json
    {
      "timestamp": "2026-05-29T10:00:00Z",
      "status": 200,
      "data": {
        "id": "uuid-string",
        "email": "user@example.com",
        "nickname": "new_nickname",
        "avatar": "new_avatar.png",
        "status": "ONLINE",
        "wins": 10,
        "losses": 5,
        "createdAt": "2026-05-29T00:00:00Z",
        "updatedAt": "2026-05-29T00:00:00Z"
      },
      "error": null
    }
    \`\`\`
- **Error Codes**:
    - `400`: 유효성 검사 실패 (닉네임 길이 초과 등)
    - `409`: 닉네임 중복 발생 (`E_CONFLICT`)

> `/api/auth/signup`·`/api/auth/login`·`/api/auth/refresh`·`/api/auth/logout`은 위
> "Authentication APIs" 절에 이미 정의돼 있다 — 이 문서에 같은 엔드포인트가 중복 정의돼 있던
> 것을 정리했다.

## 3. Security Requirements
- **JWT Authentication**: 모든 API 요청 헤더에 \`Authorization: Bearer <token>\` 필수 —
  `JwtAuthGuard`(`src/auth/guards/jwt-auth.guard.ts`), 컨트롤러에서 `@CurrentUser()` 데코레이터로
  인증된 유저를 꺼낸다.
- **CORS Policy**: 허용된 도메인(프론트엔드 URL)에서의 접근만 허용.

> Django는 이 프로젝트에 존재한 적이 없다(NestJS 단일 스택) — 위 "Django의 CSRF 미들웨어" 서술은
> 완전히 허구였으므로 삭제했다. 세션 기반 인증 자체를 쓰지 않고 순수 JWT Bearer 토큰만 사용하므로
> CSRF 미들웨어가 애초에 불필요하다.

## 3.1 `/metrics` — Prometheus 스크레이프 엔드포인트

`src/metrics/metrics.controller.ts` (`@Controller()`, 접두사 없음 — 다른 API처럼 `/api/`가
붙지 않는다). 인증 없이 Prometheus 익스포지션 포맷의 메트릭을 반환한다. `SYSTEM_ARCHITECTURE.md`의
모니터링 스택 참고.

## 4. Error Codes Mapping
| Code | Meaning | HTTP Status |
| :--- | :--- | :--- |
| \`E1001\` | 인증 토큰 만료 | 401 Unauthorized |

## Game Stats & Match History API (P3-12, feature/21-24-25-26-game-events-stats)

> 아래 엔드포인트는 `feature/21-24-25-26-game-events-stats` 브랜치에 구현됨. dev 머지 전까지 404.

### [GET] /api/game/users/{id}/stats
- **Authentication**: JWT 필수
- **Path Params**: `id` (유저 UUID)
- **Response**:
  ```json
  {
    "timestamp": "...",
    "status": 200,
    "data": {
      "wins": 12,
      "losses": 5,
      "totalGames": 17,
      "winRate": 0.71
    },
    "error": null
  }
  ```
- **winRate**: 0~1 소수 (100 곱해서 % 표시)

### [GET] /api/game/users/{id}/matches
- **Authentication**: JWT 필수
- **Path Params**: `id` (유저 UUID)
- **Query Params**: `page` (default 1), `limit` (default 10, max 50)
- **Response**:
  ```json
  {
    "status": 200,
    "data": {
      "matches": [
        {
          "id": "match-uuid",
          "hostUser": { "id": "...", "nickname": "...", "avatar": "..." },
          "guestUser": { "id": "...", "nickname": "...", "avatar": "..." },
          "winner": { "id": "...", "nickname": "..." },
          "roundsPlayed": 8,
          "createdAt": "2026-06-30T12:00:00Z"
        }
      ],
      "total": 42,
      "page": 1,
      "limit": 10
    },
    "error": null
  }
  ```
- **winner**: null이면 무승부 (미래 확장 고려)

### [GET] /api/game/leaderboard
- **Authentication**: JWT 필수
- **Response** (상위 10명, wins 내림차순):
  ```json
  {
    "status": 200,
    "data": [
      {
        "id": "user-uuid",
        "nickname": "...",
        "avatar": "...",
        "wins": 20,
        "losses": 3,
        "totalGames": 23,
        "winRate": 0.87
      }
    ],
    "error": null
  }
  ```
- wins + losses = 0인 유저는 제외됨

---

## Friends API (`src/friend/friend.controller.ts`, 전체 `@UseGuards(JwtAuthGuard)`)

> **정정 (2026-08-14)**: 예전 설계 메모는 "Auth merge 전 임시 처리로 `x-user-id` 헤더를 쓴다"고
> 적어뒀지만, 실제 컨트롤러는 처음부터 다른 API들과 동일하게 `JwtAuthGuard` +
> `@CurrentUser()` 데코레이터를 쓴다 — `x-user-id` 헤더 처리는 코드에 존재한 적이 없다.

### [POST] /api/friends/by-nickname/{nickname}
- **Description**: 닉네임으로 친구 요청 생성. **설계 메모에 없던 엔드포인트** — 실제로는
  유저 ID가 아니라 닉네임으로 찾아 요청하는 이 경로가 프론트(`LobbyPage.tsx` 친구 추가 UI)의
  기본 진입점이다.
- **Path Params**: `nickname`
- **Auth**: JWT 필수(`@CurrentUser()`로 요청자 식별)

### [POST] /api/friends/{userId}
- **Description**: 유저 ID로 친구 요청 생성
- **Path Params**: `userId` (요청 대상 유저 id)
- **Auth**: JWT 필수
- **Behavior**:
  - 자기 자신 요청 방지
  - 대상 유저 존재 검증
  - 양방향 중복/PENDING 요청 방지 → `409 Conflict('Friend request already exists')`
  - 기존 `ACCEPTED` 관계 존재 시 `409 Conflict('Already friends')`

### [PATCH] /api/friends/{requestId}
- **Description**: 친구 요청 수락/거절
- **Path Params**: `requestId`
- **Auth**: JWT 필수
- **Body**:
```json
{ "action": "accept" }
```
또는
```json
{ "action": "reject" }
```
- **Behavior**:
  - 요청 수신자만 처리 가능
  - `PENDING` 상태만 처리 가능
  - `accept`: `ACCEPTED`로 변경
  - `reject`: `PENDING` row 삭제

### [DELETE] /api/friends/{userId}
- **Description**: `ACCEPTED` 친구 관계 삭제
- **Path Params**: `userId` (삭제 대상 친구 유저 id)
- **Auth**: JWT 필수

### [GET] /api/friends/requests/sent
- **Description**: 내가 보낸(아직 `PENDING`인) 친구 요청 목록. **설계 메모에 없던 엔드포인트** —
  게임 중 중복 요청 방지 UI(`WaitingRoomPage.tsx`, `#92`)가 이 API로 대기 중 요청 여부를 미리
  확인한다.
- **Auth**: JWT 필수

### [GET] /api/friends/requests
- **Description**: 내가 받은(아직 `PENDING`인) 친구 요청 목록. **설계 메모에 없던 엔드포인트**.
- **Auth**: JWT 필수

### [GET] /api/friends
- **Description**: 내 친구 목록 조회(`ACCEPTED`만)
- **Auth**: JWT 필수
- **Response Fields (each item)**:
  - `id`
  - `nickname`
  - `status` (User 엔티티 status 필드 기반)

### 실제로 없는 것
- 별도 거절 상태(enum `REJECTED`) — 거절은 `PENDING` row 삭제로 처리한다.
- `FriendStatus`에 `BLOCKED`는 없다(`PENDING`/`ACCEPTED`뿐, `DATABASE_MODELING.md` 참고).
