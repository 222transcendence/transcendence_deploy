# Beyond Pong: Transcendence

*This project has been created as part of the 42 curriculum by [login1], [login2], [login3], [login4], [login5].*

## 1. Description
**Beyond Pong**은 고전적인 Pong 게임을 현대적인 웹 기술로 재해석한 실시간 멀티플레이어 플랫폼입니다. 실시간 웹소켓 통신, 지능형 AI 대전, 그리고 견고한 데브옵스 모니터링 시스템을 갖춘 종합 웹 서비스를 제공합니다.

### Key Features
- **Real-time Gameplay**: WebSockets을 통한 저지연 멀티플레이어 환경.
- **Remote Matchmaking**: 별도 기기의 사용자 간 실시간 원격 대전.
- **AI Opponent**: 인간의 플레이를 시뮬레이션하는 지능형 AI 알고리즘.
- **Social Interaction**: 실시간 채팅 및 친구 시스템을 통한 사용자 간 상호작용.
- **DevOps Monitoring**: Prometheus와 Grafana를 이용한 시스템 상태 시각화.

---

## 2. Team Information
| Role | Name (Login) | Responsibilities |
| :--- | :--- | :--- |
| **Product Owner (PO)** | [login1] | 기능 정의 및 우선순위 관리, 최종 모듈 검증 |
| **Project Manager (PM)** | [login2] | 스케줄 관리, 데브옵스 모니터링 시스템 구축 |
| **Technical Lead** | [login3] | 시스템 아키텍처 설계, 실시간 웹소켓 로직 설계 |
| **Developer** | [login4] | 프론트엔드 UI/UX 및 게임 물리 엔진 구현 |
| **Developer** | [login5] | 백엔드 API 및 DB ORM 스키마 설계 |

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
