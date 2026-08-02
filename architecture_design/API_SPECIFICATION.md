# API Specification v3 (Enterprise Standard)

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

### [POST] /api/auth/signup
- **Description**: 신규 사용자를 등록함.
- **Request Body**:
    ```json
    {
      "email": "user@example.com",
      "nickname": "user_nickname",
      "password": "user_password"
    }
    ```
- **Success Response (201 Created)**:
    ```json
    {
      "timestamp": "2026-06-09T12:00:00Z",
      "status": 201,
      "data": {
        "id": "uuid-string",
        "email": "user@example.com",
        "nickname": "user_nickname",
        "avatar": "default_avatar.png",
        "status": "OFFLINE",
        "wins": 0,
        "losses": 0,
        "createdAt": "2026-06-09T12:00:00Z",
        "updatedAt": "2026-06-09T12:00:00Z"
      },
      "error": null
    }
    ```

### [POST] /api/auth/login
- **Description**: 사용자 인증을 진행하고 JWT 토큰을 발급함.
- **Request Body**:
    ```json
    {
      "email": "user@example.com",
      "password": "user_password"
    }
    ```
- **Success Response (200 OK)**:
    ```json
    {
      "timestamp": "2026-06-09T12:00:00Z",
      "status": 200,
      "data": {
        "accessToken": "jwt-access-token",
        "refreshToken": "jwt-refresh-token",
        "user": {
          "id": "uuid-string",
          "email": "user@example.com",
          "nickname": "user_nickname",
          "avatar": "default_avatar.png",
          "status": "ONLINE"
        }
      },
      "error": null
    }
    ```

### [POST] /api/auth/refresh
- **Description**: Refresh 토큰으로 Access 토큰을 갱신함.
- **Request Body**:
    ```json
    {
      "refreshToken": "jwt-refresh-token"
    }
    ```
- **Success Response (200 OK)**:
    ```json
    {
      "timestamp": "2026-06-09T12:00:00Z",
      "status": 200,
      "data": {
        "accessToken": "new-jwt-access-token"
      },
      "error": null
    }
    ```

### [POST] /api/auth/logout
- **Description**: 로그아웃을 진행하고 Refresh 토큰을 만료시킴.
- **Authentication**: JWT 필수
- **Success Response (200 OK)**:
    ```json
    {
      "timestamp": "2026-06-09T12:00:00Z",
      "status": 200,
      "data": {
        "success": true
      },
      "error": null
    }
    ```

## 3. Security Requirements
- **JWT Authentication**: 모든 API 요청 헤더에 \`Authorization: Bearer <token>\` 필수.
- **CSRF Protection**: 세션 기반 인증 사용 시 Django의 CSRF 미들웨어 필수 적용.
- **CORS Policy**: 허용된 도메인(프론트엔드 URL)에서의 접근만 허용.

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
          "turnsPlayed": 8,
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

## Friends API (P2-08)

> Auth merge 전 임시 처리: current user 식별은 `x-user-id` 헤더를 사용함.

### [POST] /api/friends/{userId}
- **Description**: 친구 요청 생성
- **Path Params**: `userId` (요청 대상 유저 id)
- **Headers**: `x-user-id` (임시 current user id)
- **Behavior**:
  - 자기 자신 요청 방지
  - 대상 유저 존재 검증
  - 양방향 중복/PENDING 요청 방지
  - 기존 `ACCEPTED` 관계 존재 시 `409`

### [PATCH] /api/friends/{requestId}
- **Description**: 친구 요청 수락/거절
- **Path Params**: `requestId`
- **Headers**: `x-user-id` (임시 current user id)
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
- **Headers**: `x-user-id` (임시 current user id)

### [GET] /api/friends
- **Description**: 내 친구 목록 조회
- **Headers**: `x-user-id` (임시 current user id)
- **Response Fields (each item)**:
  - `id`
  - `nickname`
  - `status` (User 엔티티 status 필드 기반)

### Out of Scope
- JWT/Guard 기반 인증 처리
- Redis/WebSocket/session 기반 실시간 온라인 상태 동기화
- 별도 거절 상태(enum `REJECTED`) 추가
- 금지 endpoint (`/friends/request`, `/friends/accept`, `/friends/reject`) 도입
