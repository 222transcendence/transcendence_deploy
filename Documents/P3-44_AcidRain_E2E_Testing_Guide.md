# [frontend#44] Acid-Rain 백엔드 연동 E2E 검증 — 실제 대전 플로우 테스트 가이드

이 문서는 `transcendence_frontend#44`([FE] 백엔드 연동 E2E 검증 — 실제 대전 플로우)의 체크리스트를 어떤 방법으로, 어디까지 검증했는지 정리한 문서입니다. Acid-Rain(단어 낙하 타이핑 게임)의 로비→매치→대전→종료→전적 저장 전체 플로우가 실제 Socket.io 연결 위에서 계약대로 동작하는지가 목표입니다.

---

## 1. 테스트 목적 및 필요성

### 1.1 왜 필요한가?

`transcendence_backend`의 기존 `test/*.e2e-spec.ts`는 전부 `AcidRainService`/`AiPracticeService` 메서드를 인메모리로 직접 호출하고, `server.to().emit()`을 모킹하는 방식이었습니다. 즉 소켓 인증(`handleConnection`의 JWT 검증), 실제 이벤트 왕복, 재접속 시나리오(`state_sync`), 두 클라이언트가 동시에 같은 단어를 제출하는 경합 상황은 한 번도 실제 Socket.io 연결로 검증된 적이 없었습니다.

### 1.2 무엇을 검증하는가? (frontend#44 체크리스트)

1. 로비 → 매치 → 대전 → 종료 → 전적 저장 전체 플로우, 실제 소켓 통합 테스트
2. 최대 활성 단어 동시 렌더링 + 스폰 skip 확인 (인원수 비례 상한, #100)
3. `wordId` 제출, 목표 전환, 상대 선점 후 입력 유지 확인
4. `word_cleared`/`word_missed` 및 참가자별 HP 반영 확인
5. 재접속 `state_sync`에서 모든 ACTIVE 단어와 남은 시간 복구 확인
6. 2인·3~4인 PvP와 1:1 AI practice 플로우 확인
7. 콘솔 에러/경고 없이 동작 (#12 참조)

---

## 2. 테스트 진행 과정 (방법론)

세 갈래로 나눠서 진행했습니다. 각 방법이 실제로 무엇을 검증하고, 무엇을 검증하지 "못하는지"를 명확히 구분합니다.

### 2.1 백엔드: 실제 `socket.io-client` e2e 테스트 (체크리스트 1~6)

`transcendence_backend`에 `socket.io-client`를 devDependency로 추가하고, 새 스펙 `test/acid-rain-socket-flow.e2e-spec.ts`를 작성했습니다. 기존 통합 테스트(`ai-practice.server-flow.e2e-spec.ts` 등)와 동일하게 `E2E_SOCKET_INTEGRATION=1` 환경변수로 게이트하고, 실제 Postgres/Redis(`docker-compose up -d db redis`)에 연결합니다.

핵심 차이점: NestJS 테스트 앱을 `app.listen(0)`으로 실제 포트에 띄우고, `socket.io-client`로 `/game` 네임스페이스(`path: /socketio`)에 JWT 토큰을 실어 진짜 핸드셰이크를 수행합니다. 방 생성/입장/레디는 `GameService`(Redis 기반 로비 룸)를 직접 호출해 준비하고(로비 자체는 별도 프로토콜인 raw `ws` 기반이라 이번 스펙 범위 밖 — 아래 "범위 밖" 참고), 그 이후 `join_room`부터 `match_ready`/`match_start`/`word_submit`/`word_cleared`/`word_missed`/`submit_rejected`/`opponent_disconnected`/`state_sync`/`match_end`까지는 전부 실제 소켓 이벤트를 주고받습니다.

랜덤 스폰을 기다리지 않고 결정론적으로 검증하기 위해 세션에 직접 알려진 단어를 주입하는 기법을 썼습니다(기존 `ai-practice.server-flow.e2e-spec.ts`와 동일). 여기서 한 가지 함정을 발견했는데, 아래 3.1에 정리했습니다.

각 시나리오:

- **2인 PvP** — `join_room` → `match_ready`/`match_start` 동시 수신 → 정답 제출 → `word_cleared` + HP 반영 → 동시 경합(이미 클리어된 단어 재제출) → `submit_rejected(ALREADY_CLEARED)` → `word_missed` + 스플래시 데미지 반영 → 소켓 disconnect/재접속 → `state_sync`로 활성 단어·경과시간 복구 → 치명타 제출로 KO → `match_end` 수신 → DB `match_history` 저장 확인.
- **4인 PvP** — `match_ready` 참가자 4명 수신 → `maxActiveWords`가 인원 비례(20)로 설정됨 확인 → 상한까지 채운 뒤 스폰 루프가 한 틱 더 돌아도 활성 단어 수가 늘지 않음(스폰 skip) 확인.
- **1:1 AI practice** — 로비 API로 AI practice 세션 생성 → 실제 소켓으로 `join_room` → `match_ready`(AI 참가자 포함)/`match_start` 수신 → 세션이 `AI_PRACTICE` 모드로 `IN_PROGRESS` 전이 확인.

### 2.2 프론트엔드: 정적 검증 (체크리스트 7의 일부)

브라우저 자동화 도구가 이 환경에 없어 실제로 클릭·타이핑하며 콘솔을 육안 확인하는 것은 할 수 없었습니다. 대신 정적으로 확인 가능한 범위만 확인했습니다.

- `npm run build` (tsc + vite build): **통과**, 컴파일 에러 없음.
- `npm run lint`: 사전에 18개(에러 17 + 경고 1)가 있었고, 그중 안전하게 고칠 수 있는 `react-hooks/exhaustive-deps` 경고 1건(HomePage.tsx)만 수정했습니다. 나머지 17건은 아래 3.2 참고.

### 2.3 브라우저 수동 QA (자동화 불가 항목)

아래는 이번 작업에서 **실행하지 못한** 부분입니다. 4절에 체크리스트로 남겨두었으니, 실제 브라우저로 확인해 주세요.

---

## 3. 실제 테스트 수행 결과

### 3.1 백엔드 실소켓 e2e 결과: **3/3 통과**

```
E2E_SOCKET_INTEGRATION=1 npm run test:e2e -- acid-rain-socket-flow
Tests:       3 passed, 3 total
```

- 체크리스트 1(전체 플로우), 4(word_cleared/word_missed/HP), 6(2인/4인/AI practice)까지 실제 소켓 왕복으로 확인되었습니다. KO 후 `match_end` 수신과 `match_history` 신규 레코드 저장까지 이어졌습니다.
- 체크리스트 2: 4인 매치의 `maxActiveWords`는 `WORDS_PER_PLAYER(5) × 인원수` 공식대로 20이었고(#100에서 이미 인원 비례로 수정됨 — 사전 조사에서 "버그로 의심"했던 부분은 실제로는 의도된 동작이었습니다), 상한 도달 후 스폰 루프가 한 틱 더 돌아도 활성 단어 수가 늘지 않는 것을 확인했습니다.
- 체크리스트 3: 동시 경합(이미 클리어된 단어를 뒤늦게 제출)은 `submit_rejected(reason: 'ALREADY_CLEARED')`로 정확히 거부되었습니다. ("상대 선점 후 입력 유지"는 프론트엔드 UX 동작이라 브라우저 수동 확인 항목으로 남겨두었습니다 — 4절 참고.)
- 체크리스트 5: 소켓 disconnect 후 재접속 시 `state_sync`가 `activeWords`(주입해둔 단어 포함)와 `elapsedMs`, 현재 HP를 정확히 복구했습니다. `handleDisconnect`는 유예 없이 즉시 `opponent_disconnected`만 브로드캐스트하고 세션은 그대로 유지됨을 코드로 확인했습니다(#161) — 재접속에 시간제한이 없다는 뜻입니다.

**작업 중 발견한 함정 (버그 아님, 테스트 설계 이슈)**: `ActiveWord.damage` 필드는 화면 표시용일 뿐, 실제 데미지는 `submitWord`가 `damageForKeystrokes(word.keystrokes) = 5 + ceil(keystrokes/2)` 공식으로 매번 재계산합니다. 처음엔 주입한 `damage` 값을 그대로 기대해 테스트가 실패했고, 공식에 맞춰 기대값을 `keystrokes` 기반으로 재계산하도록 고쳤습니다. 실제 게임 로직에는 문제가 없었습니다.

### 3.2 프론트엔드 정적 검증 결과

- `npm run build`: 통과.
- `npm run lint`: 17개 에러가 **모두 `react-hooks/refs`("Cannot access refs during render")** 규칙입니다. `dev` 브랜치에 이미 존재하던 문제이며, 이번 작업으로 새로 생긴 것은 아닙니다. 위치:
  - `src/context/GameSocketContext.tsx:66`
  - `src/pages/GameBoardPage.tsx:103, 325-328, 348, 550, 552, 558, 585`
  - `src/pages/LobbyPage.tsx:260`
  - `src/pages/SpectateBoardPage.tsx:420`

  전부 `useRef` 값(`myUserIdRef.current`, `socketRef.current` 등)을 렌더 본문에서 직접 읽는 패턴입니다. React 공식 문서 기준으로는 "렌더 중 컴포넌트가 예상대로 갱신되지 않을 수 있는" 잠재 버그 패턴이지만, 실제 런타임에서 문제를 일으키는지는 브라우저로 확인해야 합니다. 이 게임 화면(소켓 연결, 채팅, HP 표시)의 렌더 타이밍을 안전하게 바꾸려면 각 ref의 실제 생명주기를 파악한 뒤 상태로 옮기거나 참조 전달 방식을 바꿔야 하는데, 브라우저로 회귀를 확인할 수 없는 이 환경에서 게임 대전 화면 코드를 건드리는 것은 위험 부담이 크다고 판단해 손대지 않았습니다. **이슈 #12("브라우저 콘솔 경고/에러 0개 달성")에서 다뤄야 할 항목으로 남겨둡니다.**
  - `react-hooks/exhaustive-deps` 경고 1건(HomePage.tsx)은 `navigate`가 react-router-dom v6에서 참조가 안정적이라 의존성 배열에 추가하는 것만으로 안전하게 해결해 커밋했습니다.

---

## 4. 브라우저 수동 QA 체크리스트 (미검증 — 사용자가 직접 확인 필요)

이 환경에는 Playwright 등 브라우저 자동화 도구가 없어 아래 항목은 실행하지 못했습니다. `docker-compose up`으로 스택을 띄운 뒤 실제 브라우저로 확인해 주세요.

- [ ] 로비에서 방 생성 → 2번째 탭(다른 계정)으로 참가 → 레디 → 매치 화면 진입까지 전체 플로우가 화면 전환 끊김 없이 동작하는가
- [ ] 3~4인 매치에서 화면에 최대 몇 개의 ACTIVE 단어가 동시에 표시되는지, 상한 도달 시 새 단어가 안 뜨는 게 시각적으로도 자연스러운지
- [ ] 상대가 먼저 지운 단어를 타이핑 중이던 입력이, 다른 활성 단어로 자연스럽게 재타겟팅되는지 (`submit_rejected` 수신 시 입력이 사라지는 게 의도인지 — `GameBoardPage.tsx`의 `handleSubmitRejected` 주석 기준으로는 의도된 동작이나 실제 사용자 경험으로 어색하지 않은지)
- [ ] 재접속(새로고침) 시 화면이 끊김 없이 진행 중이던 상태로 복구되는지
- [ ] 2인/3~4인 PvP, 1:1 AI practice 각각 브라우저 개발자 도구 콘솔에 에러/경고가 0개인지 (React key 누락, 404, CORS, WebSocket 연결 에러 등) — 이슈 #12 체크리스트와 동일
