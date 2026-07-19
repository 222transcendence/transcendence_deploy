# Professional Database Modeling (PostgreSQL Optimized)

## 1. Advanced ER Diagram
\`\`\`mermaid
erDiagram
    USER ||--o{ MATCH_HISTORY : participates
    USER ||--o{ FRIENDSHIP : relates
    MATCH_HISTORY ||--o{ MATCH_ACTION_LOG : records

    USER {
        uuid id PK
        string email "UNIQUE"
        string nickname "UNIQUE"
        string password "NULLABLE"
        string avatar
        enum status "ONLINE, OFFLINE, IN_GAME"
        int wins "Default: 0"
        int losses "Default: 0"
        timestamp createdAt
        timestamp updatedAt
    }

    MATCH_HISTORY {
        bigint id PK
        int host_id FK
        int guest_id FK
        int winner_id FK
        enum match_type "RANKED, NORMAL"
        int elo_change
        timestamp started_at
        timestamp ended_at
    }

    MATCH_ACTION_LOG {
        bigint id PK
        int match_id FK
        int turn_number
        enum phase "예시값"
        jsonb action_data "Optimized JSON storage"
    }
    %% 구현 노트(#14): 실제 구현은 위 두 엔티티를 분리하지 않고, MatchHistory.id를 uuid PK로
    %% 두고 matchData(jsonb) 한 컬럼에 전체 액션 로그를 저장함. 상세: DATABASE_DESIGN.md 참고.

    FRIENDSHIP {
        int user_a_id FK
        int user_b_id FK
        enum status "PENDING, ACCEPTED, BLOCKED"
        timestamp updated_at
    }
\`\`\`

## 2. Implementation Strategies
### 2.1. Concurrency Control
- **Optimistic Locking**: 게임 결과 기록 시 \`version\` 필드를 활용하여 데이터 충돌 방지.
- **Transactions**: 매치 종료 시 승리자 보상 및 랭킹 업데이트는 단일 트랜잭션 내에서 처리 (Atomicity 보장).

### 2.2. Storage Optimization
- **JSONB Usage**: \`MATCH_ACTION_LOG\`에서 \`jsonb\` 타입을 사용하여 필드 내 데이터에 대한 인덱싱 가능.
- **Partitioning**: \`MATCH_ACTION_LOG\`가 거대해질 경우 \`match_id\` 혹은 날짜별 파티셔닝 적용 고려.

## 3. Security
- **Data at Rest**: 민감 정보(2FA Secret 등)는 애플리케이션 레벨에서 암호화 후 저장.
- **GDPR Compliance**: 유저 탈퇴 시 식별 정보(username 등) 비식별화 처리 프로세스 수립.
