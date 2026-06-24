# Transcendence: Tactical Card Duel

*This project has been created as part of the 42 curriculum by hisong, jahong, jishin, kyouhele, yuhyoon.*

## 1. Description
**Transcendence**는 TCG '언라이트'를 레퍼런스로 한 턴제 덱 기반 듀얼(TCG Duel) 게임입니다. 플레이어는 전사·마법사·도적 중 한 직업의 덱을 구성하여, 드로우·이동·공격·방어의 페이즈를 통해 전략적 전투를 진행합니다. 카드 제출, 주사위 판정, 상태이상 시스템을 활용해 전투를 운영하며, 턴 제한과 판정승 규칙 등으로 승패가 결정됩니다.

### Key Features
- **Turn-based Duel System**: 드로우·이동·공격·방어 페이즈로 구성된 턴제 카드 전투.
- **Deck & Card Mechanics**: 덱 구성, 액션 카드(이동/방어/근·중·원거리 공격/특수)와 슬롯 관리.
- **AI Opponent**: 카드 기반 전략을 수행하는 AI 대전.
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
- **Users**: id, nickname, email, status, avatar
- **Games**: id, player1_id, player2_id, score, winner_id, played_at
- **ChatMessages**: id, sender_id, room_id, content, created_at
- **Friends**: id, user_id, friend_id, status

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

