# Beyond Pong: Transcendence

*This project has been created as part of the 42 curriculum by [login1], [login2], [login3], [login4], [login5].*

## 1. Description
**Beyond Pong**은 고전적인 Pong 게임을 현대적인 웹 기술로 재해석한 실시간 멀티플레이어 플랫폼입니다. 단순히 게임을 즐기는 것을 넘어, 사용자 간의 상호작용, AI 대전, 그리고 실시간 모니터링 시스템을 갖춘 종합 웹 서비스를 지향합니다.

### Key Features
- **Real-time Pong Game**: WebSockets 기반의 지연 시간 최소화 멀티플레이어 대전.
- **AI Opponent**: 사용자의 실력에 맞춰 대응하는 지능형 AI 대전 모드.
- **User Management**: 42 OAuth 및 2FA를 지원하는 보안 인증 시스템.
- **DevOps**: Prometheus와 Grafana를 활용한 서비스 상태 모니터링 및 시각화.

---

## 2. Team Information
| Role | Name (Login) | Responsibilities |
| :--- | :--- | :--- |
| **Product Owner (PO)** | [login1] | 제품 비전 정의, 백로그 관리, 기능 우선순위 결정, 최종 작업 검증 |
| **Project Manager (PM)** | [login2] | 팀 협업 조율, 스케줄링(Scrum), 위험 요소 제거 및 진행 상태 추적 |
| **Technical Lead** | [login3] | 시스템 아키텍처 설계, 기술 스택 결정, 코드 리뷰 주도 및 품질 관리 |
| **Developer** | [login4] | 프론트엔드 UI/UX 구현, 게임 물리 엔진 및 애니메이션 담당 |
| **Developer** | [login5] | 백엔드 API 설계, DB 스키마 관리, 실시간 웹소켓 로직 구현 |

---

## 3. Project Management
- **Organization**: Agile/Scrum 방법론 채택. 매주 2회 정기 스탠드업 미팅 진행.
- **Tools**: GitHub Issues 및 Projects(Kanban)를 통한 작업 단위(Ticket) 관리.
- **Communication**: Discord(실시간 소통), Slack(알림 설정), Notion(기술 문서화).

---

## 4. Technical Stack
- **Frontend**: React (TypeScript), Tailwind CSS
- **Backend**: NestJS (Node.js)
- **Database**: PostgreSQL with TypeORM
- **Infrastructure**: Docker, Docker Compose, Nginx (HTTPS)
- **Monitoring**: Prometheus, Grafana
- **Justification**: NestJS의 구조화된 아키텍처와 React의 컴포넌트 기반 개발을 통해 확장성과 유지보수성을 확보했습니다.

---

## 5. Modules & Point Calculation (Total: 14 Points)
과제 요구사항에 따른 14점 구성입니다.

| Category | Module | Type | Points | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Web** | Use a framework (FE/BE) | Major | 2 | React 및 NestJS 프레임워크 사용 |
| **Gaming** | Web-based game | Major | 2 | 실시간 멀티플레이어 Pong 구현 |
| **Gaming** | Remote players | Major | 2 | 별도 기기에서의 실시간 대전 (WebSockets) |
| **User Mgmt** | Standard User Management | Major | 2 | 프로필 관리, 아바타, 친구 시스템 |
| **AI** | AI Opponent | Major | 2 | 인간의 행동을 시뮬레이션하는 도전적인 AI |
| **DevOps** | Monitoring System | Major | 2 | Prometheus & Grafana 대시보드 구축 |
| **Web** | Use an ORM | Minor | 1 | TypeORM을 통한 효율적인 DB 관리 |
| **User Mgmt** | OAuth 2.0 (42) | Minor | 1 | 42 API를 이용한 원격 인증 |
| **Total** | | | **14** | |

---

## 6. Database Schema
- **Users**: id, email, password(hashed), nickname, avatar_url, 2fa_secret
- **Games**: id, winner_id, loser_id, score_winner, score_loser, played_at
- **Friends**: user_id, friend_id, status (pending, accepted)
- **Relations**: 
    - User : Game = 1 : N
    - User : Friend = M : N

---

## 7. Instructions
### Prerequisites
- Docker & Docker Compose
- Node.js (v18+)
- `.env` 파일 (제공된 `.env.example` 참고)

### Installation & Execution
```bash
# 1. 저장소 클론 (서브모듈 포함)
git clone --recursive https://github.com/222transcendence/transcendence_deploy.git

# 또는 이미 클론한 경우
git submodule update --init --recursive

# 2. 환경 변수 설정
cp .env.example .env

# 3. 컨테이너 실행 (한 번의 명령으로 전체 배포)
docker-compose up --build
```
이후 브라우저에서 `https://localhost`로 접속하십시오.

---

## 8. Resources & AI Usage
- **Documentation**: MDN Web Docs, NestJS Official Docs, React Dev.
- **AI Usage**: 
    - **Tasks**: 정규표현식 검증 로직 생성, Docker Compose 초기 설정 지원, 반복적인 UI 컴포넌트 스켈레톤 작성.
    - **Reflection**: AI가 생성한 코드는 반드시 팀원이 이해하고 테스트를 거친 후 프로젝트에 반영했습니다. 자세한 내용은 [AI_USAGE.md](./AI_USAGE.md)를 확인하세요.
