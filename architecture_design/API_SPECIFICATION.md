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
\`\`\`

## 2. API Endpoint Details (Highlight)

### [GET] /api/v1/matches/{id}/replay
- **Description**: 종료된 게임의 모든 액션 로그를 리플레이 형식으로 반환.
- **Query Params**: \`speed\` (Optional), \`turn_range\` (Optional)
- **Error Codes**:
    - \`403\`: 권한 없음 (비공개 매치)
    - \`404\`: 매치 정보 없음

### [POST] /api/v1/match/queue
    \`\`\`json
    { "deck_id": 101, "match_type": "RANKED" }
    \`\`\`

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
    - \`400\`: 유효성 검사 실패 (닉네임 길이 초과 등)
    - \`409\`: 닉네임 중복 발생 (\`E_CONFLICT\`)

#### Rate Limit Rationale & Client Retry Guidance

- **Rationale**: `1분에 5회` 제한은 매칭 큐에 대한 과도한 재요청(네트워크 장애로 인한 재시도 폭증, 악의적 스팸)을 방지하고, 매칭 서비스의 안정성과 공정성을 확보하기 위해 설정되었습니다. 낮은 빈도로 반복 요청이 몰릴 경우 매칭 정확도와 시스템 처리량에 악영향을 미치므로 기본 제한을 둡니다.

- **권장 클라이언트 동작 (재시도 정책)**:
  - **네트워크/타임아웃 오류**: 지수 백오프 + jitter 적용. 권장값: 초기 대기 `500ms`, 배수 `2x`, 최대 대기 `8000ms`, 최대 재시도 횟수 `5`.
  - **HTTP 429 (Too Many Requests)**: 응답의 `Retry-After` 헤더가 있을 경우 해당 값 준수. 헤더가 없으면 위 지수 백오프 정책을 사용하고, 총 재시도는 `5`회를 넘기지 말 것.
  - **Idempotency**: 중복 진입을 방지하려면 요청에 `Idempotency-Key`(UUID)를 헤더로 포함시키는 것을 권장합니다. 서버는 동일 키로 들어온 중복 요청을 지정된 윈도우(예: 2분) 내에서 idempotent하게 처리합니다.

- **예시(의사코드, JS)**:

```javascript
async function enqueueWithRetry(body) {
  const maxAttempts = 5;
  let attempt = 0;
  let delay = 500;
  const idempotencyKey = uuidv4(); // include in header

  while (attempt < maxAttempts) {
    attempt++;
    try {
      const res = await fetch('/api/v1/match/queue', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Idempotency-Key': idempotencyKey },
        body: JSON.stringify(body)
      });

      if (res.status === 200) return await res.json();
      if (res.status === 429) {
        const ra = parseInt(res.headers.get('Retry-After') || '0', 10);
        const wait = ra > 0 ? ra * 1000 : delay;
        await sleep(wait + jitter());
      } else {
        throw new Error('request failed: ' + res.status);
      }
    } catch (err) {
      if (attempt >= maxAttempts) throw err;
      await sleep(delay + jitter());
      delay = Math.min(delay * 2, 8000);
    }
  }
}
```

- **서버 권장 동작**: 서버는 `Idempotency-Key`을 지원하고, 429 응답 시 `Retry-After` 헤더를 설정하여 클라이언트가 재시도 시점을 알 수 있게 합니다. 또한, 매칭 큐 진입 로직은 중복 처리 방지를 위해 요청 시점의 사용자 상태(이미 대기중인지) 확인을 우선합니다.

위 지침은 기본 권고이며, 실제 운영 환경에서는 사용자 행동 분석과 시스템 부하를 바탕으로 레이트 리미트 값을 조정하세요.

## 3. Security Requirements
- **JWT Authentication**: 모든 API 요청 헤더에 \`Authorization: Bearer <token>\` 필수.
- **CSRF Protection**: 세션 기반 인증 사용 시 Django의 CSRF 미들웨어 필수 적용.
- **CORS Policy**: 허용된 도메인(프론트엔드 URL)에서의 접근만 허용.

## 4. Error Codes Mapping
| Code | Meaning | HTTP Status |
| :--- | :--- | :--- |
| \`E1001\` | 인증 토큰 만료 | 401 Unauthorized |
| \`E2001\` | 매칭 큐 중복 진입 | 400 Bad Request |
| \`E3001\` | 존재하지 않는 덱 선택 | 404 Not Found |

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
