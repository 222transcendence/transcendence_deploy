# Architecture Decision Records (ADR)

## 1. Backend: Django + Django Channels
- **Decision**: 비동기 처리가 가능한 Django Channels를 백엔드 프레임워크로 선정.
- **Rationale**: 
    - 42 과제의 권장 사항 준수.
    - 게임 로직(Python의 풍부한 라이브러리 활용)과 실시간 통신(WebSockets)을 한 프레임워크 내에서 관리 가능.
    - 강력한 ORM을 통한 데이터 무결성 보장.

## 2. Frontend: React + TypeScript
- **Decision**: 컴포넌트 기반의 React와 타입 안정성을 위한 TypeScript 사용.
- **Rationale**:
    - 복잡한 카드 UI 및 상태 변화가 잦은 게임 화면을 선언적으로 관리 가능.
    - TCG 특성상 많은 데이터 타입을 다루므로 TypeScript의 정적 타이핑이 필수적임.

## 3. Real-time Communication: WebSockets (Pub/Sub via Redis)
- **Decision**: Redis를 Channel Layer로 사용하는 WebSocket 통신.
- **Rationale**:
    - HTTP 폴링 방식보다 낮은 지연 시간(Low Latency) 보장.
    - Redis의 고속 인메모리 처리를 통해 게임 세션 데이터 동기화 최적화.

## 4. Game Logic Authority: Server-side Engine
- **Decision**: 모든 게임 로직 연산(주사위, 데미지, 상태이상)은 서버에서 수행.
- **Rationale**:
    - 클라이언트 측 조작(Cheating) 방지.
    - 호스트/클라이언트 간의 상태 불일치 원천 차단.
