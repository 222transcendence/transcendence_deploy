# Architecture Decision Records (ADR)

## ADR-001: 실시간 게임 엔진 — NestJS + Socket.IO 권위 서버
* **Status**: Accepted (실제 구현과 일치)
* **Context**: 실시간 타자 대전의 공정성을 위해 클라이언트 조작을 방지해야 하고, 42 프로젝트
  요구사항(WebSocket 기반 실시간 통신, JWT 인증)을 충족해야 함.
* **Decision**: 모든 게임 판정(스폰, 정오답, HP, 랭킹)을 서버에서 수행하는 Authoritative
  Server 패턴을 NestJS의 `@WebSocketGateway`(Socket.IO 기반, `/game`·`/chat` 네임스페이스)와
  raw `ws`(`/ws/lobby`) 위에 구현한다.
* **Consequences**:
    - **장점**: 클라이언트 조작 원천 봉쇄, 단일 진실 공급원(SSOT) 확보. NestJS 데코레이터
      기반 Guard/Pipe로 인증·검증을 REST와 WebSocket에 동일하게 적용 가능.
    - **트레이드오프**: 서버 부하가 판정 로직에 집중되고, 아래 ADR-004에서 다루는 대로 현재
      단일 인스턴스로만 확장 가능하다.

## ADR-002: 계층형 NestJS 모듈 구조 (엄밀한 Hexagonal 아님)
* **Status**: Accepted (실제 구현과 일치, 단 원래 제안된 형태와는 다름)
* **Context**: 초기 설계는 Domain Core(순수 로직)를 Web/DB 프레임워크로부터 완전히 분리하는
  Hexagonal(Ports & Adapters) 아키텍처를 목표로 했음.
* **Decision**: 실제로는 NestJS의 표준 계층 구조(Controller/Gateway → Service → Repository)를
  그대로 따른다. `AcidRainService`가 TypeORM 리포지토리와 `RedisService`를 직접 주입받아
  쓰며, 별도의 포트 인터페이스로 인프라를 추상화하지 않는다. 다만 서비스 단위로 책임을 나누는
  느슨한 모듈화("Modular Monolith")는 유지된다 — `game`/`lobby`/`chat`/`friend`/`auth`/`user`
  모듈이 명확히 분리돼 있다.
* **Consequences**:
    - **장점**: NestJS 관용구를 그대로 따라 팀 전체의 학습 비용이 낮고, 실제로 빠르게
      구현·반복할 수 있었다.
    - **트레이드오프**: 순수 Hexagonal 대비 유닛 테스트가 TypeORM/Redis 목(mock)에 더 의존한다
      (`acid-rain.service.spec.ts` 등이 리포지토리를 직접 목킹). 다만 이번 세션에서 실제
      docker 부팅 테스트로 DI 버그를 잡은 사례가 보여주듯, 목킹만으로는 못 잡는 문제도 있다.

## ADR-003: 실시간 게임 상태의 실제 저장소 — 인메모리, Redis는 백업/재접속 스냅샷 전용
* **Status**: Accepted (실제 구현), 원래 제안(Redis Cluster 우선 저장)은 **Superseded**
* **Context**: 단어 스폰/판정, HP 갱신 등 빈번한 쓰기가 발생하는 진행 중 매치 상태를 어디에
  둘지 결정해야 함.
* **Decision (실제)**: `AcidRainService`가 `Map<roomId, AcidRainSession>` 형태로 모든 진행
  중 매치 상태를 **Node.js 프로세스 메모리**에 들고 있다. 모든 판정은 이 인메모리 객체를 직접
  읽고 쓴다. Redis(`game:acidroom:{roomId}` 키, `persistSession()`)는 재접속 시 복구용
  스냅샷과 관전 진입 시 초기 상태 조회를 위한 **부차적 직렬화본**일 뿐, 판정의 원본이 아니다.
  최종 결과(`MatchHistory`/`MatchParticipant`/`ParticipantPerformance`)만 PostgreSQL에
  영속화한다.
* **Consequences**:
    - **장점**: Redis 왕복 없이 메모리에서 즉시 판정하므로 매우 빠르고 구현이 단순하다.
    - **트레이드오프**: 백엔드 프로세스가 재시작되면 진행 중이던 모든 매치의 인메모리 상태가
      완전히 유실된다(Redis 백업은 있지만 자동 복구 로직이 프로세스 재시작 시 이를 다시
      읽어들이지 않는다 — 재접속 시에만 참조됨). 그리고 이 설계는 **백엔드 다중 인스턴스
      운영을 근본적으로 막는다** — 자세한 내용과 파급 효과는 ADR-004.
* **Superseded design**: 원래는 Redis Cluster를 게임 상태의 1차 저장소로 두고, hash-tag 기반
  key co-location, `MOVED`/`ASK` 처리, 슬롯 리샤딩 대응까지 계획했었다. 실제로 Redis는
  단일 인스턴스(`redis:7-alpine` 컨테이너 1개)로만 구성돼 있고 클러스터 모드가 아니므로, 이
  설계는 구현되지 않았다.

## ADR-004: 백엔드는 단일 인스턴스로만 운영 가능
* **Status**: Accepted (현재 상태의 기록), 향후 변경 여지 있음
* **Context**: ADR-003의 인메모리 세션 저장 방식과, Socket.IO가 Redis 어댑터
  (`@socket.io/redis-adapter` 등) 없이 구성돼 있다는 점이 결합되면, 백엔드 컨테이너를 2개
  이상 띄웠을 때 같은 방의 참가자가 서로 다른 인스턴스에 연결될 수 있다 — 그러면 판정 순서
  보장이 깨지고 인메모리 세션이 인스턴스마다 따로 놀아 게임이 정상 동작하지 않는다.
* **Decision**: 지금은 이 제약을 그대로 받아들이고 백엔드를 정확히 1개 컨테이너로만
  운영한다(`docker-compose.yml`에 `deploy.replicas`나 로드밸런싱 설정이 없음 —
  `SYSTEM_ARCHITECTURE.md` §3/§4). 42 프로젝트 규모의 트래픽에서는 단일 인스턴스로 충분하다고
  판단했다.
* **Consequences**:
    - **장점**: 분산 락, 방 단위 sticky 라우팅, Socket.IO 어댑터 설정 등의 복잡도를 avoid.
    - **트레이드오프**: 수평 확장이 필요해지면 최소한 (1) Socket.IO Redis adapter 도입,
      (2) 게임 세션 상태를 Redis 등 공유 저장소로 이전, (3) 방 단위 sticky 라우팅 또는 분산
      락 도입이 선행돼야 한다(`WEBSOCKET_PROTOCOL.md` §6.3의 레이스 컨디션 절에 이미 이
      전제가 명시돼 있다). 이 세 가지 모두 현재 구현돼 있지 않다.

## ADR-005: 체크포인팅/장애 복구 — 제안됐으나 구현되지 않음, 대신 "그레이스 타이머 없음" 정책 채택
* **Status**: 원래 제안(Redis Cluster 체크포인팅)은 **Rejected/Not Implemented**. 실제
  채택된 정책은 Accepted.
* **Context**: Redis 장애나 네트워크 분리 시 진행 중 게임 세션을 어떻게 보호할지에 대해,
  원래는 PostgreSQL `game_checkpoints` 테이블에 주기적 스냅샷을 쓰고 장애 시 재생(replay)하는
  정교한 체크포인팅 시스템을 제안했었다(Celery/RabbitMQ/Sidekiq 워커, 5초 주기, `seq` 기반
  idempotent 복구 등).
* **Decision (실제)**: 이 체크포인팅 시스템은 구현되지 않았다 — `game_checkpoints` 테이블도,
  워커 큐도 코드에 없다. 대신 훨씬 단순한 정책을 채택했다(`backend#161`): **연결이 끊겨도
  매치를 일시정지하지 않고 그대로 진행시키며, 강제 탈락 유예 타이머를 두지 않는다.** 끊긴
  참가자는 스스로 공격은 못 하지만 스플래시 데미지는 계속 받을 수 있어 자연스러운 페널티가
  있고, 매치 자체가 180초 하드 타임아웃을 가지므로 무한정 멈춰있지 않는다. 재접속은 아무 때나
  `join_room` 재전송으로 가능하며 `state_sync`로 즉시 복구한다(`AI_OPPONENT_SPEC.md` §3.1/
  UC-AI-05 참고 — AI 연습전도 동일 정책).
* **Consequences**:
    - **장점**: 훨씬 단순한 구현, 화장실을 다녀오거나 새로고침이 오래 걸리는 정상적인 상황을
      게임에서 쫓아내지 않음.
    - **트레이드오프**: Redis 자체가 죽으면 재접속 복구(`state_sync`)가 불가능해진다(다만
      인메모리 매치 자체는 백엔드 프로세스가 살아있는 한 계속 진행된다, ADR-003). 서버가
      재시작되면 그 시점의 모든 진행 중 매치가 유실된다 — 이 리스크를 완화하는 자동 복구는
      아직 없다.

## ADR-006: 산성비(Acid Rain) 실시간 타자 대전 채택
* **Status**: Accepted
* **Context**: 실시간 멀티플레이 웹 게임이라는 요구사항에 부합하면서 한국어 타이핑이라는
  차별화 요소를 살릴 수 있는 게임 장르가 필요했다.
* **Decision**: 게임을 실시간 한국어 타자 대전("산성비")으로 구현했다. 카드/캐릭터 기반
  설계를 배제하고 `AcidRainService`/`AcidRainGateway`를 판정 엔진의 중심으로 삼았다.
* **Consequences**:
    - `GAME_DESIGN.md`가 산성비 규칙의 정본이며, `WEBSOCKET_PROTOCOL.md`,
      `AI_OPPONENT_SPEC.md`, `DATABASE_DESIGN.md`, `API_SPECIFICATION.md`가 이를 뒷받침한다.

## ADR-007: Prometheus + Grafana 모니터링 스택 도입
* **Status**: Accepted
* **Context**: 게임 세션·API 요청에 대한 실시간 지표 가시성이 필요했다.
* **Decision**: `docker-compose.yml`에 `prometheus`(scrape 대상: 백엔드 `GET /metrics`,
  `node-exporter`), `node-exporter`(호스트 시스템 지표), `grafana`(대시보드, provisioning
  기반 자동 구성)를 각 단일 컨테이너로 추가했다. 백엔드는 커스텀 메트릭(활성 게임 수, 단어
  판정 카운터, HTTP 요청 인터셉터 등)을 노출한다.
* **Consequences**:
    - **장점**: 배포 환경에서 실시간 지표를 즉시 확인 가능(`deploy#4` EPIC).
    - **트레이드오프**: Grafana 관리자 비밀번호는 `.env`의 `GRAFANA_ADMIN_PASSWORD`로
      설정하며 기본값(`change_me_in_production`)을 반드시 교체해야 한다 — `.env`는
      gitignore 처리돼 저장소에 커밋되지 않는다.
