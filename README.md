# Transcendence: 산성비 (Acid Rain) Real-time Typing Battle

*This project has been created as part of the 42 curriculum by hisong, jahong, jishin, kyouhele, yuhyoon.*

## 1. Description
**Transcendence**는 실시간 2인 타자 대전 게임 **산성비(Acid Rain)**입니다. 서버가 동일한 단어 스트림을
양쪽 플레이어에게 동시에 브로드캐스트하면, 화면 위에서 단어가 떨어지고 먼저 정확히 입력한 플레이어가
그 단어를 지우며 상대에게 데미지를 줍니다. 아무도 지우지 못한 단어가 바닥에 닿으면 양쪽 모두 데미지를
입습니다. 서버가 스폰 타이밍/순서와 판정을 전적으로 결정하는 권위 서버(authoritative server) 구조로,
상대 HP를 먼저 0으로 만들거나 제한 시간(180초) 내 더 높은 HP를 유지하면 승리합니다.

> 상세 규칙은 `architecture_design/GAME_DESIGN.md`, 이벤트 스키마는
> `architecture_design/WEBSOCKET_PROTOCOL.md` §6 참고.

### Key Features
- **Real-time Typing Battle**: 서버 권위 기반으로 동기화된 단어 스폰 스트림과 정오답 판정.
- **Remote Players**: 서로 다른 컴퓨터의 두 플레이어가 실시간으로 대전, 재접속 유예/복구 지원.
- **2~4인 배틀로얄**: 참가자 수에 비례한 단어량·인접 레인 회피 등 N인 전용 판정 로직.
- **Spectator Mode**: 진행 중인 매치를 제3자가 실시간으로 관전.
- **AI Opponent**: `AI_OPPONENT_SPEC.md` 기준의 인간형 단어 입력 AI 대전, 실제 유저 성능 기반 개인화.
- **Social Interaction**: 채팅, 친구, 프로필/전적 시스템을 통한 사용자 상호작용.
- **DevOps Monitoring**: Prometheus 기반 메트릭 수집과 Grafana 대시보드.

---

## 2. Team Information
| Role | Name (Login) | Responsibilities |
| :--- | :--- | :--- |
| **Product Owner (PO)** | yuhyoon | 기능 정의·백로그 관리·최종 모듈 검증; 게임 판정 로직(동시 탈락 타이브레이크·랭킹 산정) 구현 및 회귀 테스트 작성 |
| **Project Manager (PM)** | kyouhele | 회의 일정·스프린트 조율·진행 추적·팀 커뮤니케이션 관리; AI 대전 모듈 전담 설계·구현(인간형 타이핑 AI, 난이도 스케일링, 유저 성능 기반 개인화) |
| **Technical Lead** | hisong | 시스템 아키텍처 설계·기술 스택 결정·코드 리뷰; 실시간 게임 엔진(AcidRainService/Gateway) 및 WebSocket/Socket.IO 프로토콜 설계·구현 |
| **Developer** | jahong | 프론트엔드 화면 초기 설계·구현(게임 보드·로비·대기실·프로필·전적/리더보드), 게임 소켓 컨텍스트 및 애니메이션 컴포넌트 |
| **Developer** | jishin | 소셜 기능 백엔드 전담(친구 요청·수락·거절·온라인 상태, 채팅 API/Gateway); DB ORM 엔티티·마이그레이션 설계 |

### 개별 기여 내역 (Individual Contributions)
> Git 커밋 이력(작성자 이메일 기준)을 근거로 작성했습니다. 세부 항목은 각 팀원 확인 후 갱신 예정입니다.

| 로그인 | 주요 기여 |
| :--- | :--- |
| **yuhyoon** (PO) | 기능 우선순위 관리(GitHub Projects Phase 단위 이슈 관리), 최종 모듈 검증(`CHECKLIST.md`); 백엔드 Acid Rain 게임 핵심 로직(`src/game`) 구현, 매치 결과 저장/전적 히스토리(`recordMatchHistory`), 유저 프로필 관련 프론트 페이지 |
| **hisong** (Tech Lead) | 시스템 아키텍처 설계, 실시간 웹소켓 로직 설계; 백엔드 게임/로비/인증 모듈(`src/game`, `src/lobby`, `src/auth`), 프론트 페이지/타입/훅 기반 구조 |
| **jishin** (Developer) | 백엔드 API 및 DB ORM 스키마 설계; 게임/채팅/로비/단어사전/친구 모듈(`src/game`, `src/chat`, `src/word-dictionary`, `src/friend`), 프론트 다수 페이지 |
| **jahong** (Developer) | 프론트엔드 UI/UX(`src/pages`, `src/components` 다수); 백엔드 유저 모듈(`src/user`) 일부 |
| **kyouhele** (PM) | 스케줄 관리, 데브옵스 모니터링 시스템 구축(Prometheus/Grafana); 백엔드 게임/친구/마이그레이션/메트릭 모듈 기여 |

### 프로젝트 관리 방식
- **GitHub Projects 보드**로 전체 작업을 Phase 1~8(인프라 → 핵심 기능 → 고급 모듈 → 하드닝/평가 준비)로 나누고, 각 작업을 고유 ID(`P1-01` 등)를 가진 이슈로 관리했습니다. 이슈 상태는 Backlog → Ready → In Progress → In Review → Done으로 흐릅니다.
- PO(yuhyoon)가 기능 우선순위를 정해 Phase/이슈를 배치하고, PM(kyouhele)이 일정과 진행 상황을 관리했습니다.
- 커밋 메시지에 이슈/체크리스트 ID를 남기는 컨벤션(`feat(scope): 요약 [P2-01]`)으로 구현-검증-커밋 증빙을 1:1 대응시켰으며, 그 결과물이 `CHECKLIST.md`입니다.
- 브랜치 전략과 커밋 컨벤션 상세는 §9 참고.

---

## 3. Technical Stack
| Stack | Choice | 선택 이유 |
| :--- | :--- | :--- |
| Frontend Framework | React (TypeScript) | 컴포넌트 기반 재사용성과 타입 안전성, 팀 내 사전 경험 |
| Backend Framework | NestJS (Node.js) | 모듈/DI 구조가 명확해 인증·게임·채팅 등 도메인별 모듈 분리에 적합, TypeScript 일관성 유지 |
| Real-time | Socket.io (WebSockets) | 룸(room) 기반 브로드캐스트와 재연결 처리를 기본 제공해 게임/채팅/로비 네임스페이스 분리에 적합 |
| Database / ORM | PostgreSQL / TypeORM | 관계형 데이터(매치 기록, 참가자, 친구 관계 등) 무결성 보장, NestJS와의 통합 용이성 |
| Cache / Session State | Redis | 게임 세션/실시간 상태처럼 휘발성이 큰 데이터를 빠르게 읽고 쓰기 위함 |
| Reverse Proxy / HTTPS | Nginx + self-signed TLS | 단일 HTTPS 진입점으로 프론트/백엔드 트래픽을 통합하고 평가 환경에서 인증서 발급 없이 HTTPS 요구사항 충족 |
| Monitoring | Prometheus, node-exporter, Grafana | DevOps Monitoring 모듈 요구사항 충족 및 컨테이너/서비스 상태 가시화 |
| Infrastructure | Docker, Docker Compose | 단일 명령어(`docker-compose up --build`)로 전체 스택 배포 요구사항 충족 |

---

## 4. Modules & Point Calculation (Total: 22 Points)
선택한 모듈 리스트 및 점수 계산입니다. (통과 기준: 14점, 보너스 상한 +5 — 아래 "점수 집계 방식" 참고) 각 모듈의 최종 검증 상태는 `CHECKLIST.md`와 평가 전 스모크 테스트 결과를 기준으로 확인합니다.

| Category | Module | Type | Points | Owner | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Web** | Use a framework (FE/BE) | Major | 2 | hisong, jahong | React 및 NestJS 프레임워크 사용 |
| **Web** | Real-time features | Major | 2 | hisong, yuhyoon | WebSockets 기반 실시간 동기화 |
| **Web** | User Interaction | Major | 2 | jishin, jahong | 채팅, 프로필, 친구 시스템 구현 |
| **Web** | Use an ORM | Minor | 1 | jishin, hisong | TypeORM을 통한 효율적인 데이터 관리 |
| **User Management** | Standard user management | Major | 2 | jishin, jahong | 프로필 수정, 아바타 업로드(기본 아바타 포함), 친구+온라인 상태 |
| **User Management** | Game statistics & match history | Minor | 1 | yuhyoon, jishin | 전적/승률/매치 히스토리, 리더보드 |
| **User Management** | Remote authentication (OAuth 2.0) | Minor | 1 | jishin, hisong | 42 intra OAuth 2.0 로그인 |
| **AI** | AI Opponent | Major | 2 | kyouhele, yuhyoon | `architecture_design/AI_OPPONENT_SPEC.md` 기준 인간형 AI 대전, 유저 성능 기반 개인화 |
| **Gaming** | Web-based game | Major | 2 | yuhyoon, hisong | 실시간 웹 기반 산성비 타자 대전 |
| **Gaming** | Remote players | Major | 2 | yuhyoon, hisong | 원격 사용자 간의 온라인 대전 |
| **Gaming** | Multiplayer (3+ players) | Major | 2 | yuhyoon, kyouhele | 2~4인 배틀로얄 판정 엔진 |
| **Gaming** | Spectator mode | Minor | 1 | yuhyoon, jahong | 진행 중인 매치 실시간 관전 |
| **DevOps** | Monitoring System | Major | 2 | hisong, kyouhele | Prometheus & Grafana 대시보드 |
| **Total** | | | **22** | | |

### 점수 집계 방식
과제 기준(통과 14점 + 보너스 최대 5점)에 따라, 위 22점 중 **14점은 필수 통과분**, 나머지 8점 중 **최대 5점만 보너스로 인정**됩니다(과제 명세 §VII Bonus part). 즉 실질 반영 점수는 최대 **19점**이며, 나머지 3점은 초과분으로 상한에 걸립니다. 어떤 모듈을 "필수 14점"에 포함하고 어떤 것을 "보너스"로 분류하는지는 채점자 재량이므로, 위 13개 모듈 전부를 그대로 유지하고 데모 시 전부 시연 가능한 상태를 유지합니다.

### 모듈별 구현 근거 (Evidence)
모든 모듈은 실제 코드를 기준으로 아래 위치에서 직접 확인 가능합니다.

- **Use a framework (FE/BE)**: `transcendence_frontend`(React + TypeScript + Vite), `transcendence_backend/src/main.ts`(NestJS, `@nestjs/platform-express`).
- **Real-time features**: `AcidRainGateway`(`/game` 네임스페이스), `ChatGateway`(`/chat`), `LobbyGateway`(raw `/ws/lobby`) — 전부 Socket.IO/WebSocket 기반. 연결 끊김·재접속은 그레이스 타이머 없이 `state_sync`로 즉시 복구(`backend#161`).
- **User Interaction**: 채팅(`chat/chat.gateway.ts`, `chat/chat.controller.ts`, `GET /api/chat/history`), 프로필(`GET /api/users/{id}`, `GET /api/users/me`), 친구(`friend/friend.controller.ts` — 요청/수락/거절/삭제/목록/보낸요청/받은요청).
- **Use an ORM**: TypeORM, `transcendence_backend/src/data-source.ts`(엔티티: User, Friend, ChatMessage, MatchHistory, MatchParticipant, WordDictionary, ParticipantPerformance, WordAttemptRecord, KeystrokeRecord 등).
- **Standard user management**: 아바타 업로드(`POST /api/users/me/avatar`, 기본 아바타 포함), 프로필 수정(`PATCH /api/users/me`), 친구+온라인 상태(`User.status`: ONLINE/OFFLINE/IN_GAME), 프로필 페이지(`transcendence_frontend/src/pages/ProfilePage.tsx`).
- **Game statistics & match history**: `GET /api/game/users/:id/stats`, `GET /api/game/users/:id/matches`, `GET /api/game/leaderboard`; 프론트 `StatsPage.tsx`, `LeaderboardPage.tsx`.
- **Remote authentication (OAuth 2.0)**: `GET /api/auth/42`, `GET /api/auth/42/callback`(passport-42 `FtStrategy`).
- **AI Opponent**: `AiScheduler`/`AiExecutor`/목표 선택(`state-evaluator.ts`) — BEGINNER/NORMAL/HARD 난이도별 반응시간·오타·포기 확률 차등, 실제 유저 성능 데이터 기반 개인화(`PerformanceService`, `PlayerPerformanceProfileProvider`), 판단 과정은 `ai_monitor_snapshot` 이벤트로 실시간 시각화(`architecture_design/WEBSOCKET_PROTOCOL.md` §6.8).
- **Web-based game**: `AcidRainService`/`AcidRainGateway`, 규칙은 `architecture_design/GAME_DESIGN.md`.
- **Remote players**: 서로 다른 브라우저/기기의 두 플레이어가 실시간 대전, 연결 끊김 시에도 매치 지속 및 재접속 복구.
- **Multiplayer (3+ players)**: `AcidRainSession.participants[]`(2~4인), 참가자 수 비례 동시 활성 단어량, 인접 레인 회피, N인 탈락/랭킹 판정(`player_eliminated` 이벤트 실시간 브로드캐스트).
- **Spectator mode**: `spectate_room`/`leave_spectate` 이벤트, 프론트 `SpectateBoardPage.tsx` — 참가자 목록에 등록되지 않는 읽기 전용 관전.
- **Monitoring System**: `docker-compose.yml`의 `prometheus`/`node-exporter`/`grafana` 서비스, 백엔드 `GET /metrics`(커스텀 카운터: 활성 게임 수, 단어 판정 이벤트 등), `grafana/provisioning` 대시보드 프로비저닝.

---

## 5. Database Schema
- **Users**: id, nickname, email, password, avatar, status, wins, losses
- **MatchHistory**: id, hostUser(nullable, 2인 매치 하위호환), guestUser(nullable), winner, mode(PVP/AI_PRACTICE), roundsPlayed, matchData(jsonb), createdAt
- **MatchParticipant**: id, matchId, userId, finalHp, rank — N인(2~4) 매치 참가자별 결과
- **WordDictionary**: id, text, language, contentType, difficulty, category, length, keystrokes, isActive — 단어 은행(DB 테이블)
- **WordAttemptRecord** / **KeystrokeRecord**: 단어별 제출 시도 / 키스트로크 단위 원장 — 반응시간·오타·수정 분석용
- **ParticipantPerformance**: 매치별 참가자 집계 성능 — AI 개인화 파이프라인의 데이터 소스
- **ChatMessages**: id, sender_id, room_id, content, type(NORMAL/INVITE/SYSTEM), created_at
- **Friends**: id, requesterId, receiverId, status(PENDING/ACCEPTED)

전체 스키마 상세는 `architecture_design/DATABASE_DESIGN.md`, `architecture_design/DATABASE_MODELING.md` 참고.

---

## 6. Instructions
### Prerequisites
- Docker & Docker Compose
- Git with submodule support
- `.env` 파일 설정 (제공된 `.env.example` 참고)

### Installation & Execution
```bash
# 1. 저장소 클론 (서브모듈 포함)
git clone --recursive https://github.com/222transcendence/transcendence_deploy.git

# 2. 환경 변수 설정
cp .env.example .env

# 3. 컨테이너 실행
docker-compose up --build
```
이후 `https://localhost`에서 서비스를 확인할 수 있습니다.

### Local Port Override
42클러스터 컴퓨터처럼 기본 포트가 막혀 있으면, base 파일은 그대로 두고 로컬 전용 override를 덮어씁니다.

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
```

기본값은 다음처럼 잡혀 있습니다.

| Service | Local Port |
| :--- | :--- |
| Web App / HTTPS | `8443` |
| Web App / HTTP | `8080` |
| Frontend Direct | `8081` |
| Backend Direct | `3000` |
| PostgreSQL | `5432` |
| Redis | `6380` |
| Prometheus | `9090` |
| node-exporter | `9101` |
| Grafana | `3001` |

필요하면 실행 시 환경변수로 바로 바꿀 수 있습니다.

```bash
HTTP_HOST_PORT=8082 HTTPS_HOST_PORT=8444 REDIS_HOST_PORT=6381 docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
```

### First-run Verification
처음 실행하는 평가자는 아래 순서로 기본 동작을 확인할 수 있습니다.

1. `cp .env.example .env`
2. `docker-compose up --build`
3. Chrome에서 `https://localhost` 접속
4. 회원가입 후 로그인
5. 로비에서 방 생성/입장, 준비 완료 후 산성비 매치 시작
6. 채팅, 친구 목록, 프로필/전적 화면 접근 확인
7. `https://localhost/privacy-policy`, `https://localhost/terms-of-service` 접근 확인
8. Prometheus와 node-exporter 컨테이너가 실행 중인지 확인

### Service Endpoints
| Service | URL | Purpose |
| :--- | :--- | :--- |
| Web App | `https://localhost` | React frontend through Nginx HTTPS |
| Backend Health | `https://localhost/api/health` | NestJS health check |
| Backend Direct | `http://localhost:3000` | Internal API service exposed for local debugging |
| Frontend Direct | `http://localhost:8080` | Frontend container exposed for local debugging |
| Prometheus | `http://localhost:9090` | Metrics query UI |
| Node Exporter | `http://localhost:9100/metrics` | Host/container metrics exporter |

---

## 7. Resources & AI Usage
- **Documentation**: NestJS Docs, React Dev, Socket.io Documentation, `architecture_design/AI_OPPONENT_SPEC.md`.
- **AI Usage**: [AI_USAGE.md](./AI_USAGE.md) 파일에 상세 기록되어 있습니다.

---

## 8. Evaluation Checklist
평가 전 최종 확인 항목입니다.

- `docker-compose up --build` 한 번으로 전체 스택이 실행됩니다.
- 최신 안정 버전 Chrome에서 콘솔 에러/경고 없이 주요 화면이 동작합니다.
- 모든 백엔드 통신은 Nginx HTTPS 엔드포인트를 통해 접근합니다.
- 이메일/비밀번호 로그인은 bcrypt 해시와 salt를 사용하며, DB에 평문 비밀번호를 저장하지 않습니다.
- Privacy Policy와 Terms of Service 페이지는 푸터 또는 직접 URL로 접근 가능합니다.
- README의 팀원 로그인, 선택 모듈, 실행 방법, 브랜치/커밋 규칙이 최신 상태입니다.
- AI 사용 내역은 [AI_USAGE.md](./AI_USAGE.md)에 기록되어 있고, PR 리뷰에서 팀원이 검토합니다.

---

## 9. Git Flow & Commit Conventions

### Branching Strategy
본 프로젝트(transcendence_deploy, transcendence_backend, transcendence_frontend 3개 저장소 공통)는 다음 브랜치 전략을 따릅니다:

- **`main`**: 릴리스 브랜치. `dev`에서 검증이 끝난 변경사항만 머지되며, 릴리스 시점마다 `vX.Y.Z` 태그를 남깁니다.
- **`dev`**: 발행 전 테스트(통합) 브랜치. 모든 기능 브랜치는 PR을 통해 이 브랜치로 먼저 병합되어 통합 테스트를 거칩니다. `dev`가 안정화되면 PR로 `main`에 머지하고 태그를 생성합니다.
- **`<type>/<issue-number>-<short-description>`**: 개별 작업 브랜치. GitHub Projects/Issues의 이슈 번호에 맞춰 `dev`에서 분기합니다.
  - `<type>`: `feature`(또는 `feat`) / `fix` / `docs` / `chore` / `refactor` / `test` 중 작업 성격에 맞는 값
  - `<issue-number>`: 연동된 이슈 번호
  - `<short-description>`: 영문 kebab-case 요약
  - 예: `feature/11-profile-api`, `feat/13-friends-api`, `docs/13-friends-api-docs`, `fix/9-jwt-guard-bug`
  - 작업 완료 후 PR을 `dev`로 올리고, 1명 이상의 승인 및 CI 통과 후 머지합니다. `dev`에만 머지된 브랜치는 삭제하지 않고 남겨두되, 해당 변경이 `main`으로 릴리스되면 그 시점에 브랜치를 삭제합니다.

```
main  ──●────────────●─────────────▶  (release, tagged vX.Y.Z)
         \            \
dev    ───●──●──●──●──●─────────────▶  (pre-release test/integration)
            \   \   \
issue/*      ●   ●   ●                (feature/<#>-desc, fix/<#>-desc, ...)
```

### Commit Message Convention
모든 커밋 메시지는 협업 규칙을 따르기 위해 다음 형식을 준수합니다:
```
<type>(<scope>): <subject> [ID] (옵션)
```
- **`feat`**: 새 기능 (모듈, 엔드포인트 추가 등)
- **`fix`**: 버그 수정
- **`refactor`**: 코드 구조 개선 (기능 변화 없음)
- **`docs`**: 문서 추가/수정
- **`test`**: 테스트 코드 추가/수정
- **`chore`**: 빌드 설정, 패키지 의존성 관리 등 기타 작업

예시:
`feat(auth): 회원가입 API 추가 및 bcrypt 해싱 적용 [P2-02]`
