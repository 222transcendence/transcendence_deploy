# Detailed System Architecture (Hexagonal v2)

## 1. Physical Topology
시스템의 하드웨어/컨테이너 계층 구조입니다.

\`\`\`mermaid
graph TD
    Internet((Internet)) --> Nginx[NGINX Reverse Proxy/Load Balancer]
    Nginx --> SSL[SSL Termination]
    SSL --> Daphne[Daphne ASGI Server]
    
    subgraph "Application Layer"
        Daphne --> Channels[Django Channels]
        Daphne --> Rest[DRF REST API]
        Channels <--> Engine[Core Game Engine]
    end

    subgraph "Infrastructure Layer"
        Redis[(Redis Cluster)]
        DB[(PostgreSQL)]
        Queue[Task Queue - Celery]
    end

    Channels <--> Redis
    Rest --> DB
    Engine --> Redis
    Engine --> DB
\`\`\`

## 2. Hexagonal Logic Architecture (Software Design)
비즈니스 로직의 독립성을 보장하기 위한 포트 및 어댑터 설계입니다.

\`\`\`mermaid
graph LR
    subgraph "Input Adapters"
        API[REST Controller]
        WS[WebSocket Consumer]
    end

    subgraph "Domain Core (Pure Logic)"
        Battle[Battle Logic]
        Dice[Dice Engine]
        Phase[Phase Manager]
    end

    subgraph "Output Adapters"
        Persist[DB Repository]
        Cache[Redis State Store]
    end

    API --> Battle
    WS --> Battle
    Battle --> Persist
    Battle --> Cache
\`\`\`

## 3. Scalability & HA
- **Horizontal Scaling**: Daphne 서버를 여러 컨테이너로 띄워 Redis Channel Layer를 통해 메시지 공유.
- **Failover**: PostgreSQL 복제본(Read Replica) 및 Redis Sentinel 고려.
- **Monitoring**: Prometheus + Grafana를 통한 실시간 게임 세션 지표 트래킹.

- **Redis Cluster Note**: 다이어그램은 `Redis Cluster`를 가리키며, 운영 시 클러스터 특성을 고려해야 합니다. 구체적인 분산 키 설계(해시 태그를 통한 key co-location), `MOVED`/`ASK` 처리, 리샤딩 중의 재시도/토폴로지 갱신, 그리고 체크포인팅 기반 복구 절차는 각각의 ADR에 문서화되어 있습니다(참조: ADR 003, ADR 004). 클라이언트는 클러스터-aware 라이브러리를 사용하고, 리샤딩·노드 재배치 중에는 체크포인트 폴백을 통해 상태를 복원합니다.
