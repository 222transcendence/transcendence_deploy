### Testing & Monitoring Guidance
#### 테스트 시나리오
- **리샤딩(Resharding) 테스트**: 클러스터에 슬롯 마이그레이션을 트리거하고(예: 테스트 토폴로지에서 `redis-cli --cluster reshard`), 게임 세션의 지속성 및 복구 절차를 검증합니다. 목표는 `MOVED`/`ASK` 응답 발생 시 클라이언트가 토폴로지를 갱신하고 체크포인트 폴백이 정상 동작하는지 확인하는 것입니다.
- **노드 재시작/오프라인 시뮬레이션**: 특정 Redis 노드를 재시작하거나 분리한 뒤(예: Docker 컨테이너 재시작) 체크포인트 기반 복구와 액션 로그 재생이 정상 작동하는지 확인합니다.
- **네트워크 분리(Partition) 테스트**: 네트워크 분리를 시뮬레이션하여 일시적 네트워크 장애 동안 복구 절차와 Grace Period 정책(15s)이 의도대로 동작하는지 검증합니다.
- **워크플로우 레이턴시·부하 테스트**: 체크포인트 워커(비동기 영속화) 성능을 부하 테스트하여 체크포인트 쓰기 지연과 재시도율을 측정합니다.
- **클라이언트 토폴로지 캐시 검증**: 클라이언트 라이브러리의 `CLUSTER SLOTS` 갱신 주기, `MOVED`/`ASK` 처리 로직, 자동 재연결 동작을 유닛·통합 테스트로 확인합니다.
#### 간단한 실패 주입 예시 (개발환경)
- 노드 재시작 (docker-compose 환경 예시):
```bash
docker-compose restart redis-node-2
```
- 슬롯 마이그레이션(테스트용):
```bash
redis-cli --cluster reshard 127.0.0.1:7000 --from <source-node-id> --to <target-node-id> --slots 100
```
- 네트워크 드롭(로컬 테스트): `tc` 명령으로 패킷 드롭/지연을 시뮬레이션합니다(루트 권한 필요).
#### 모니터링 지표(Metrics)
- `checkpoint_success_rate` — 체크포인트 쓰기 성공 비율
- `checkpoint_latency_ms` — 체크포인트 영속화 지연
- `checkpoint_worker_retry_count` — 워커 재시도 횟수
- `recovery_success_rate` — 장애 발생 후 체크포인트 또는 로그 재생으로 복구된 세션 비율
- `redis_moved_count` — 클러스터에서 `MOVED` 응답 횟수(이상 징후)
- `redis_slot_migrations` — 슬롯 이동 진행 중 여부 및 지속 시간
- `redis_key_miss_count` — Redis에서 키 미스 발생 빈도

이들 지표는 Prometheus로 수집하고 Grafana 대시보드에 시각화합니다.

#### Alerting (권장 임계값 예)

- 체크포인트 실패율 > 5% (5분 기준) → PagerDuty 알림
- 복구 성공률 < 95% (10분 기준) → 심각도 경고
- 슬롯 마이그레이션이 10분 이상 지속 → 운영자 경고
- 체크포인트 영속화 지연 99p 지연값 > 2s → 성능 경고

#### 보존 정책

- 기본 보존: 각 `room_id`에 대해 최신 체크포인트 5개(또는 24시간 이내 생성된 것)를 보관합니다.
- 정기 삭제 예시(SQL):

```sql
DELETE FROM game_checkpoints
WHERE id NOT IN (
    SELECT id FROM game_checkpoints g2
    WHERE g2.room_id = game_checkpoints.room_id
    ORDER BY seq DESC LIMIT 5
) AND created_at < now() - interval '24 hours';
```

위 작업은 배치(Job)로 주기 실행(cron, Kubernetes CronJob 등)합니다.

#### 운영 검증

- 장애 주입 실험(Chaos Testing)을 정기적으로 수행하여 체크포인팅·복구 워크플로우를 검증합니다.
- 플레이어에게 영향을 줄 수 있는 운영 작업(대규모 리샤딩)은 낮은 트래픽 시간대에 시행하고 사전 체크포인팅을 권장합니다.

---
# Architecture Decision Records (ADR) - Advanced v2

## ADR 001: Web-Authoritative Game Engine & Django Channels
* **Status**: Accepted
* **Context**: 실시간 게임의 공정성을 위해 클라이언트 조작을 방지해야 하며, 42 프로젝트의 기술적 제약을 충족해야 함.
* **Decision**: 모든 게임 로직 연산을 서버에서 수행하는 Authoritative Server 패턴을 채택하고, Django Channels를 통해 실시간 상태를 브로드캐스트함.
* **Consequences**:
    - **장점**: 클라이언트 핵(Hack) 원천 봉쇄, 단일 진실 공급원(SSOT) 확보.
    - **트레이드오프**: 서버 부하 증가 및 네트워크 지연에 따른 사용자 경험 저하 가능성 (Client Prediction으로 보완 예정).

## ADR 002: Modular Monolith with Hexagonal Architecture
* **Status**: Accepted
* **Context**: 초기 빠른 개발 속도와 향후 마이크로서비스로의 확장성 사이의 균형 필요.
* **Decision**: 비즈니스 로직(Domain)을 인프라(DB, Web)와 분리하는 헥사고날 아키텍처 패턴 적용.
* **Consequences**:
    - **장점**: 게임 엔진 로직을 웹 프레임워크 없이 테스트 가능, DB 교체가 용이함.
    - **트레이드오프**: 코드 구조의 복잡성 증가.

## ADR 003: Redis-based Game State Caching
* **Status**: Accepted
* **Context**: 단어 스폰/판정, HP 갱신 등 빈번한 데이터 쓰기 발생 시 PostgreSQL의 I/O 병목 우려.
* **Decision**: 진행 중인 게임 세션의 휘발성 데이터는 Redis에 보관하고, 최종 결과만 PostgreSQL에 기록.
* **Consequences**:
    - **장점**: 초당 수만 건의 게임 액션 처리 가능.
    - **트레이드오프**: Redis 장애 시 진행 중인 세션 유실 위험 (Checkpointing으로 보완).

### Cluster Considerations

운영 환경에서는 Redis Cluster를 사용한다고 가정합니다. 클러스터 운영·개발에서 반드시 지켜야 할 권고사항은 다음과 같습니다.

- **Key co-location (hash tags)**: 한 게임 `room`과 관련된 모든 키(예: 상태, 액션 로그, 잠금 키)는 동일 해시 슬롯에 위치시킵니다. 키 네이밍 예:
    - `room:{<room_id>}:state`
    - `room:{<room_id>}:actions`
    이렇게 하면 관련 키들이 같은 슬롯에 묶여 원자적 연산(Lua 스크립트 등)이 가능해집니다.

- **클러스터 인식 클라이언트 사용**: 서버는 클러스터를 인식하고 `MOVED`/`ASK` 응답을 자동으로 처리하는 검증된 클러스터 클라이언트(예: `ioredis` cluster, `redis-py-cluster`, `Lettuce`)를 사용해야 합니다.

- **단일 슬롯 원자성**: 복합 연산은 가능하면 단일 슬롯에서 수행합니다(Lua). 다중 슬롯을 건너뛰는 연산은 피하고, 불가피하면 애플리케이션 레벨에서 설계 변경을 고려합니다.

- **리샤딩 대비**: 리밸런싱(resharding) 중에는 `MOVED`/`ASK` 응답 및 일시적 접근 불가가 발생할 수 있습니다. 클라이언트는 해당 응답을 수신하면 토폴로지를 갱신하고 재시도해야 하며, 재시도는 지수 백오프와 제한 횟수를 둡니다.

- **액션 로그와 스토리지 폴백**: Redis Streams 또는 키 기반 액션 로그를 동일 슬롯에 유지하여 장애 시 로그 재생으로 상태를 복원하도록 설계합니다. 또한 주기적 체크포인팅을 통해 PostgreSQL에 영속화합니다.

이 권고는 ADR 003의 기본 결정(휘발성 데이터는 Redis 보관, 최종 결과는 PostgreSQL 기록)을 변경하지 않습니다.

***

## ADR 004: Redis Checkpointing & Recovery Strategy
* **Status**: Proposed
* **Context**: Redis(특히 Cluster) 장애, 네트워크 분리, 또는 리샤딩 중 키 재배치로 인해 휘발성 게임 세션 데이터가 일시적으로 접근 불가가 될 수 있음. ADR 003에서 체크포인팅을 완화 수단으로 명시했지만, 구체적 전략이 필요함.
* **Decision**: Redis에 보관되는 진행 중 세션 상태에 대해 다음 체크포인팅·복구 전략을 채택한다.

### 체크포인팅 원칙

- **목표**: 진행 중인 게임의 일관된 복원점을 주기적으로 생성하여 Redis 장애나 키 재배치 시 최소한의 손실로 세션을 복구한다.
- **저장소(영속화 대상)**: PostgreSQL에 `game_checkpoints` 테이블을 사용하여 JSONB 형태로 저장한다. 스키마 예:

```sql
CREATE TABLE game_checkpoints (
    id BIGSERIAL PRIMARY KEY,
    room_id UUID NOT NULL,
    seq BIGINT NOT NULL,
    state JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(room_id, seq)
);
CREATE INDEX ON game_checkpoints (room_id, seq DESC);
```

- **체크포인트 주기(권장 기본값)**:
    - 시간 기반: 기본값 `every 5s` (구성 가능)
    - 이벤트 기반: 새로운 라운드/페이즈 시작, 점수 변경, 플레이어 액션 수가 N개(권장: 50) 도달 시 즉시 체크포인팅
    - 강제: 연결 종료 임박(Grace period 만료 직전) 또는 수동 운영 플래그에 의해 즉시 체크포인팅

- **증분/버전 관리**: 각 체크포인트는 `seq`(서버 측 시퀀스 번호)를 포함합니다. 복구 시 최신 `seq`를 사용하여 재적용/재생 여부를 판단합니다.

### 구현 세부안

- **원자적 생성**: Redis에서 상태를 업데이트할 때 Lua 스크립트를 이용해 상태 변경과 액션 로그(또는 스트림 항목 추가)에 대해 단일 슬롯 원자성을 유지합니다. 이후 비동기 워커가 해당 상태를 PostgreSQL로 비동기 영속화합니다.
- **비동기 영속화 워커**: 체크포인트 쓰기는 워커 큐(예: RabbitMQ, Sidekiq, Celery)를 통해 처리해 요청 처리 지연을 최소화합니다. 워커는 체크포인트 성공/실패를 로깅하고 실패 시 재시도 정책을 적용합니다.
- **폴백(Recovery) 절차**:
    1. 서버가 Redis에서 `room:{id}:state` 키를 찾지 못하거나 접근 오류가 발생하면, 우선 클러스터-aware 클라이언트로 `MOVED`/`ASK` 처리를 시도하여 재요청합니다.
    2. 재시도에도 실패하면, 데이터베이스의 최신 체크포인트(`SELECT state FROM game_checkpoints WHERE room_id=? ORDER BY seq DESC LIMIT 1`)를 가져옵니다.
    3. 체크포인트와 함께 보관된 액션 로그(가능하다면 Redis Streams 또는 별도 영속 로그)를 사용해 누락된 액션을 재생(replay)하여 최신 상태로 복원합니다.
    4. 복원 실패 시(예: 체크포인트 없음)에는 세션을 안전하게 종료하거나 사용자에게 재매치/복구 불가 메시지를 보냅니다.

- **일관성**: 체크포인트는 항상 `seq`를 포함하여 idempotent 복구를 보장합니다. 재생 로직은 `seq`보다 큰 항목만 적용합니다.

### 주기성·보존·모니터링

- **Retention**: 체크포인트는 `latest` N개(예: 5) 또는 T시간(예: 24h)만 보존하고 오래된 것은 주기적으로 삭제합니다.
- **모니터링 지표**: 체크포인트 실패율, 영속화 지연(latency), 워커 재시도 횟수, 복구 성공률을 모니터링하고 경고를 설정합니다.

### 테스트·운영 검증

- 장애 주입(네트워크 분리, 노드 재시작, 리샤딩) 시 체크포인팅 및 복구 절차를 E2E로 검증합니다.
- 클라이언트 라이브러리의 `MOVED`/`ASK` 처리, 토폴로지 갱신 동작을 정기적으로 시뮬레이션 테스트합니다.

### Consequences

- 체크포인팅은 Redis 의존도를 줄이고 복구 가능성을 높이나, PostgreSQL 쓰기량과 복구 코드 복잡도가 증가합니다. 비동기 워커와 모니터링이 필수입니다.

이 ADR은 ADR 003을 보완하여 체크포인팅의 빈도, 저장 방식, 복구 절차를 명확히 규정합니다.
