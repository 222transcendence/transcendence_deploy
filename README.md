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
- **AI Opponent**: 사람처럼 지연을 갖고 반응하는 AI 대전 (예정).
- **Social Interaction**: 채팅 및 친구 시스템을 통한 사용자 상호작용.
- **DevOps Monitoring**: Prometheus와 Grafana를 이용한 시스템 상태 시각화.

---

## 2. Team Information
| Role | Name (Login) | Responsibilities |
| :--- | :--- | :--- |
| **Product Owner (PO)** | yuhyoon | 기능 정의 및 우선순위 관리, 최종 모듈 검증 |
| **Project Manager (PM)** | kyouhele | 스케줄 관리, 데브옵스 모니터링 시스템 구축 |
| **Technical Lead** | hisong | 시스템 아키텍처 설계, 실시간 웹소켓 로직 설계 |
| **Developer** | jahong | 프론트엔드 UI/UX |
| **Developer** | jishin | 백엔드 API 및 DB ORM 스키마 설계 |

---

## 3. Technical Stack
- **Frontend Framework**: React (TypeScript)
- **Backend Framework**: NestJS (Node.js)
- **Real-time**: Socket.io (WebSockets)
- **Database / ORM**: PostgreSQL / TypeORM
- **Monitoring**: Prometheus, Grafana
- **Infrastructure**: Docker, Docker Compose

---

## 4. Modules & Point Calculation (Total: 15 Points)
선택한 모듈 리스트 및 점수 계산입니다. (통과 기준: 14점)

| Category | Module | Type | Points | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Web** | Use a framework (FE/BE) | Major | 2 | React 및 NestJS 프레임워크 사용 |
| **Web** | Real-time features | Major | 2 | WebSockets 기반 실시간 동기화 |
| **Web** | User Interaction | Major | 2 | 채팅, 프로필, 친구 시스템 구현 |
| **Gaming** | Web-based game | Major | 2 | 실시간 웹 기반  게임 |
| **Gaming** | Remote players | Major | 2 | 원격 사용자 간의 온라인 대전 |
| **AI** | AI Opponent | Major | 2 | 인간의 행동을 시뮬레이션하는 AI 대전 |
| **DevOps** | Monitoring System | Major | 2 | Prometheus & Grafana 대시보드 |
| **Web** | Use an ORM | Minor | 1 | TypeORM을 통한 효율적인 데이터 관리 |
| **Total** | | | **15** | |

---

## 5. Database Schema
- **Users**: id, nickname, email, password, avatar, status, wins, losses
- **MatchHistory**: id, hostUser, guestUser, winner, roundsPlayed, matchData(jsonb), createdAt
- **ChatMessages**: id, sender_id, room_id, content, created_at
- **Friends**: id, requesterId, receiverId, status

전체 스키마 상세는 `architecture_design/DATABASE_DESIGN.md` 참고.

---

## 6. Instructions
### Prerequisites
- Docker & Docker Compose
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

---

## 7. Resources & AI Usage
- **Documentation**: NestJS Docs, React Dev, Socket.io Documentation.
- **AI Usage**: [AI_USAGE.md](./AI_USAGE.md) 파일에 상세 기록되어 있습니다.

---

## 8. Git Flow & Commit Conventions

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

