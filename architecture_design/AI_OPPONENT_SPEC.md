# 산성비 AI 대전 기능 명세서

> 기준 브랜치: `transcendence_backend/dev`  
> 관련 문서: `architecture_design/GAME_DESIGN.md`, `architecture_design/WEBSOCKET_PROTOCOL.md`(§6.8 `ai_monitor_snapshot`), `USE_CASES.md`  
> 담당 범위: AI Opponent Major 모듈 및 상시 AI 대전 사용자 흐름

---

## 1. 목적과 제품 정의

AI 대전은 온라인 상대가 없어도 언제든 한 판을 플레이할 수 있도록 제공하는 **상시 1인 대전 모드**다. 별도의 미션·경험치·레벨 해금 구조를 두지 않으며, 온라인 대전과 같은 게임 규칙·게임 화면·시간별 난이도 상승을 사용한다.

사용자는 사람과 동일한 게임 규칙을 사용하는 AI와 한 판을 완주하며, 경기 종료 후 정확도·반응 속도·처리 단어 수 등 연습 결과를 확인한다. AI는 정답을 즉시 제출하는 완벽한 봇이 아니라, 선택한 난이도에 따라 인지 지연·타이핑 속도·오타·수정·포기 행동을 보이는 인간형 상대여야 한다.

AI 연습전은 사용자 1명 대 AI 1명의 1:1 전용 모드지만, 단어 스폰·상태 전이·데미지 계산은
`GAME_DESIGN.md`의 공통 전략 규칙과 같은 엔진 판정을 사용한다. 이 문서는 2~4인 PvP 범위를 대체하거나
제한하지 않는다.

### 1.1 평가 요구사항 대응

AI Opponent Major 모듈을 충족하기 위해 다음을 보장한다.

- AI가 게임 규칙에 따라 정상적으로 플레이한다.
- AI가 충분히 경쟁력 있게 플레이하고 실제로 사용자를 이길 수 있다.
- AI가 항상 완벽하게 플레이하지 않고 인간과 유사한 반응 편차와 실수를 보인다.
- 게임 커스텀 옵션을 제공하는 경우 AI도 같은 옵션을 적용받는다.
- 팀원이 평가 중 목표 선택, 반응 시간, 오타·포기, 난수 시드, 공정성, 한계를 설명할 수 있다.

### 1.2 AI 대전 운영 정책

- AI 대전 결과는 **PvP 승수·패수·랭킹·리더보드에 반영하지 않는다.**
- 한 판의 승리·패배·무승부는 결과 화면에 표시하되, 경쟁 등급에는 영향을 주지 않는다.
- AI 대전 기록은 개인 통계로 저장할 수 있다.
- 사용자 연결 끊김이나 서버 오류로 정상 완주하지 못한 세션은 패배가 아니라 `ABORTED` 또는 `VOID`로 처리한다.

---

## 2. 범위

### 2.1 MVP 포함 범위

- 로그인 사용자 1명과 서버 제어 AI 1명의 비공개 연습 세션
- Beginner·Normal·Hard AI 실력 선택
- 대인전과 동일한 단어 스트림, HP, 제한 시간, 데미지, 승패 규칙
- AI의 인간형 반응 시간, 타이핑 속도, 오타, 수정, 포기
- 연습 결과 및 개인 통계 표시
- 재대전, 난이도 변경, 로비 복귀
- 연결 끊김 시 일시정지와 복귀
- 서버 권위 판정, 멱등 처리, 세션 정리

### 2.2 MVP 제외 범위

- AI 대전 결과의 PvP 리더보드 반영
- 실시간 고무줄 보정 또는 사용자 몰래 난이도 변경
- LLM을 이용한 실시간 단어 생성
- 빨강 공격·파랑 회복 등 미확정 특수 단어 규칙
- AI 대전방의 공개 방 목록 노출
- AI 대전방 관전, 친구 초대, 토너먼트 참가
- AI를 실제 사용자 계정으로 생성하는 방식
- 독립 AI 레벨업, 경험치, 단계 해금, `MISSION COMPLETE` 시스템

---

## 3. 공통 게임 규칙

| 항목 | 규칙 |
|---|---|
| 게임 형태 | 사용자 1명 대 AI 1명의 연습 대전 |
| 초기 HP | 양쪽 100 |
| 제한 시간 | 180초 |
| 정타 데미지 | 상대에게 `5 + ceil(keystrokes / 2)` |
| 바닥 도달 | 양쪽 모두 3 데미지 |
| 승리 | 상대 HP 0 이하 또는 시간 종료 시 더 높은 HP |
| 동률 | 시간 종료 또는 동일 이벤트로 양쪽 HP가 동시에 0 이하가 되면 무승부 |
| 판정 | 서버 권위, 최초 유효 제출만 승인 |
| 난이도 램프 | 경과 시간에 따라 스폰 간격·낙하 속도·단어 구간 증가 |
| 전략 선택 | 짧은 단어는 성공하기 쉽지만 공격력이 낮고, 긴 단어는 입력 부담이 크지만 공격력이 높음 |

### 3.1 상태 머신 (실제 구현)

```text
CREATING → COUNTDOWN → IN_PROGRESS → FINISHED
```

`AcidRainSession.status`의 실제 타입은 `'COUNTDOWN' | 'IN_PROGRESS' | 'FINISHED'` 세 가지뿐이다.
설계 당시 계획했던 `PAUSED`/`ABORTED` 상태는 **구현되지 않았다** — 사용자 연결이 끊겨도 매치
시계·스폰 루프·AI는 멈추지 않고 그대로 진행된다(`backend#161`, PvP와 동일 정책). 대신 매치
결과(`MatchEndReason`: `'KO' | 'TIME_LIMIT' | 'FORFEIT'`)와 별도로, 저장되는 `ResultStatus`
(`'FINISHED' | 'ABORTED' | 'VOID'`, `participant-performance.entity.ts`)가 있는데 이는 세션
상태 머신이 아니라 **개인 성능 기록(§6.9)을 population-default 통계에 반영할지 판단하는
데이터 품질 플래그**다 — `winnerId`가 확정되면 `FINISHED`, 아니면 `ABORTED`로 표시되어 그
매치의 표본이 통계 계산에서 제외된다.

- `CREATING`: 연습 세션 생성 및 게임 화면 진입 준비
- `COUNTDOWN`: 3·2·1 카운트다운
- `IN_PROGRESS`: 스폰, 입력, 판정, HP 변경 진행. 사용자 연결이 끊겨도 계속 진행되며, 재접속 시
  `state_sync`로 복구한다(UC-AI-05)
- `FINISHED`: 승리·패배·무승부로 정상 종료(180초 하드 타임아웃 포함)

---

## 4. 사용자 경험

### 4.1 진입 방식

로비에 `AI 대전` 버튼을 항상 제공한다.

1. 사용자가 로비에서 `AI 대전`을 선택한다.
2. AI 실력 선택 화면에서 `Beginner`, `Normal`, `Hard` 중 하나를 선택한다.
3. 각 단계 선택 패널에는 AI의 반응 속도·타속·실수 성향을 짧게 표시한다.
4. `대전 시작`을 누르면 서버가 비공개 AI 대전 세션을 생성한다.
5. 게임 화면으로 이동하고 카운트다운 후 시작한다.

온라인 대전 매칭이 일정 시간 동안 성사되지 않은 경우에도 `AI와 대전하기`를 제안한다. 선택 시 같은 AI 실력 선택 화면으로 이동하며, 사용자가 원하면 온라인 매칭을 계속 기다릴 수 있다. 매칭 중 AI 대전을 선택하면 기존 온라인 매칭 요청을 먼저 취소한 뒤 AI 세션을 생성한다.

### 4.2 AI 실력 선택 화면

AI 실력 선택은 **게임 스테이지 선택이 아니라 상대 AI의 기본 실력 선택**이다. 세 단계는 처음부터 모두 선택 가능하며 잠금·해금 조건이 없다.

| 화면 요소 | 표시 및 동작 |
|---|---|
| 화면 제목 | `AI 실력 선택` |
| 안내 문구 | `게임 규칙과 시간별 난이도 상승은 온라인 대전과 동일합니다.` |
| Beginner 선택 패널 | `반응이 느리고 실수가 많아요` |
| Normal 선택 패널 | `평균적인 속도와 정확도로 플레이해요` |
| Hard 선택 패널 | `빠르고 정확하지만 가끔 실수해요` |
| 기본 선택 | `Normal` |
| 시작 버튼 | `AI 대전 시작` |
| 뒤로가기 | 로비 또는 기존 매칭 화면으로 복귀 |
| 랭킹 안내 | `AI 대전 결과는 PvP 랭킹에 반영되지 않습니다.` |

선택한 패널은 테두리·색상·체크 표시로 구분한다. 난이도를 선택하지 않은 상태를 허용한다면 시작 버튼을 비활성화하고, 기본값을 `Normal`로 둘 경우에는 화면 진입 즉시 시작할 수 있다. 접근성을 위해 색상만으로 선택 상태를 표현하지 않는다.

```text
[ AI 실력 선택 ]

[ Beginner ]   [ Normal ✓ ]   [ Hard ]
 느림·실수 많음   균형형          빠름·정확함

 게임 규칙과 시간별 난이도 상승은 온라인 대전과 동일합니다.
 AI 대전 결과는 PvP 랭킹에 반영되지 않습니다.

              [ AI 대전 시작 ]
```

### 4.3 게임 화면 표시

- 상대 닉네임: `ACID BOT`
- 상대 영역: `AI` 배지와 난이도 표시
- 상단 또는 결과 화면: `AI 대전 — PvP 랭킹 미반영` 안내
- 대인전과 동일한 HP, 남은 시간, 낙하 단어 표시
- AI의 실제 입력 문자열이나 내부 판단 점수는 게임 중 노출하지 않음

### 4.4 결과 화면

정상 종료 시 다음을 표시한다.

- 승리·패배·무승부
- 최종 HP
- 사용자와 AI의 단어 제거 수
- 사용자 정확도
- 사용자 평균 반응 시간
- 바닥까지 놓친 단어 수
- 사용자 최고 연속 정답
- 연습 시간
- `같은 AI와 다시 대전`
- `AI 실력 변경`
- `로비로`

선택 기능으로 사용자가 자주 틀렸거나 놓친 단어를 최대 5개까지 보여줄 수 있다.

---

## 5. AI 대전 유스케이스

### UC-AI-01. AI 대전 진입 및 실력 선택

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | AI 대전 진입 및 실력 선택 |
| 액터 | 로그인 사용자 |
| 시작 조건 | 사용자가 로비에 있으며 다른 방이나 진행 중인 게임에 속하지 않음 |
| 트리거 | 사용자가 `AI 대전` 버튼을 누르거나 온라인 매칭 실패 안내에서 `AI와 대전하기`를 선택함 |
| 기본 흐름 | 1. 서버가 사용자의 활성 게임 여부를 확인한다.<br>2. AI 실력 선택 화면을 표시한다.<br>3. 사용자가 Beginner·Normal·Hard 중 하나를 선택한다.<br>4. `AI 대전 시작` 버튼이 활성화된다. |
| 대안 흐름 | **1A** 사용자가 이미 다른 방이나 게임에 속해 있으면 새 세션을 만들지 않고 기존 방으로 복귀하거나 먼저 나가라는 안내를 표시한다.<br><br>**3A** 난이도를 선택하지 않은 경우 시작 버튼을 비활성화한다.<br><br>**3B** 클라이언트가 잘못된 난이도 값을 전송하면 서버가 요청을 거절하고 모달에 오류를 표시한다. |
| 종료 조건 | 유효한 AI 실력이 선택되고 대전 시작 요청이 가능한 상태가 된다. |

### UC-AI-01A. 온라인 매칭에서 AI 대전으로 전환

| 항목 | 내용 |
|---|---|
| 액터 | 온라인 매칭 대기 사용자 |
| 시작 조건 | 온라인 상대가 정해진 시간 동안 매칭되지 않음 |
| 트리거 | 서버가 매칭 지연 상태를 알림 |
| 기본 흐름 | 1. 화면에 `AI와 대전하기`와 `계속 기다리기`를 표시한다.<br>2. 사용자가 `AI와 대전하기`를 선택한다.<br>3. 서버가 온라인 매칭 큐 이탈을 확정한다.<br>4. AI 실력 선택 화면으로 이동한다.<br>5. 사용자가 실력을 선택하고 AI 대전을 시작한다. |
| 대안 흐름 | **2A** `계속 기다리기`를 선택하면 매칭 큐를 유지한다.<br><br>**3A** 큐 이탈 전에 온라인 상대가 확정되면 중복 세션을 만들지 않고 온라인 대전을 우선하거나 사용자에게 선택을 다시 확인한다. 정책은 한 가지로 고정한다. |
| 종료 조건 | 사용자가 온라인 큐와 AI 세션에 동시에 속하지 않는다. |

### UC-AI-02. AI 대전 세션 생성 및 시작

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | AI 대전 세션 생성 및 시작 |
| 액터 | 로그인 사용자, AI 시스템 참가자 |
| 시작 조건 | UC-AI-01 완료, 유효한 난이도 선택 |
| 트리거 | 사용자가 `AI 대전 시작`을 누름 |
| 기본 흐름 | 1. 클라이언트가 고유 `requestId`와 AI 실력을 서버에 전송한다.<br>2. 서버가 사용자당 활성 게임 잠금을 원자적으로 확인한다.<br>3. 서버가 비공개 AI 대전 세션과 새 `roomId`, `matchId`, 난수 시드를 생성한다.<br>4. AI 참가자를 시스템 플레이어로 즉시 준비 완료 처리한다.<br>5. 클라이언트가 게임 네임스페이스에 연결하고 방에 입장한다.<br>6. 서버가 `match_ready`와 `match_start`를 전송한다.<br>7. 3·2·1 카운트다운 후 `IN_PROGRESS`가 된다. |
| 대안 흐름 | **1A** 같은 `requestId`가 재전송되면 기존 생성 결과를 반환하고 새 세션을 만들지 않는다.<br><br>**2A** 이미 활성 세션이 있으면 해당 세션 정보를 반환하거나 생성 요청을 거절한다.<br><br>**3A** 세션 생성에 실패하면 생성한 임시 상태와 잠금을 정리하고 로비에 오류·재시도 UI를 표시한다.<br><br>**5A** 게임 소켓 연결이 제한 시간 내 완료되지 않으면 세션을 정리하고 로비로 돌아간다. |
| 종료 조건 | 사용자와 AI가 동일한 연습 세션에 있고 게임이 `IN_PROGRESS` 상태가 된다. |

### UC-AI-03. 사용자와 AI의 단어 경쟁

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | 사용자와 AI의 단어 경쟁 |
| 액터 | 사용자, AI 시스템 참가자 |
| 시작 조건 | AI 대전 세션이 `IN_PROGRESS`이고 활성 단어가 존재 |
| 트리거 | 서버가 새 단어를 스폰함 |
| 기본 흐름 | 1. 서버가 사용자 화면에 `word_spawn`을 전송하고 같은 단어 정보를 AI 판단기에 전달한다.<br>2. AI는 활성 단어 중 하나를 목표로 선택한다.<br>3. 사용자와 AI는 각자 입력을 시도한다.<br>4. 서버는 제출 요청을 공통 판정 함수로 처리한다.<br>5. 최초 유효 정답 제출만 승인한다.<br>6. 서버가 단어 제거, 데미지, HP, 통계를 갱신하고 결과 이벤트를 보낸다. |
| 대안 흐름 | **2A** AI가 해당 단어를 인지하지 못하거나 포기하면 제출하지 않는다.<br><br>**3A** AI가 오타를 내면 내부 오타 시도를 기록하고 수정 지연 후 단어가 여전히 활성 상태일 때만 다시 제출한다.<br><br>**4A** 제출 문자열이 틀리면 서버가 제출을 거절하되 단어는 유지한다. 정확한 오류 코드명은 WebSocket 계약 정렬 이슈에서 확정한다.<br><br>**4B** 같은 제출 시도가 재전송되면 중복 처리하지 않고 이전 결과를 반환한다. 공개 payload 계약은 WebSocket 계약 정렬 이슈에서 확정한다.<br><br>**5A** 단어가 이미 제거되었거나 바닥에 도달했다면 서버가 제출을 거절한다. 정확한 오류 코드명은 WebSocket 계약 정렬 이슈에서 확정한다.<br><br>**6A** AI 제출과 바닥 도달이 경합하면 `ACTIVE → CLEARED` 또는 `ACTIVE → MISSED` 중 하나만 원자적으로 성공한다. |
| 종료 조건 | 해당 단어가 최대 한 번만 해결되고 HP와 통계가 일관되게 반영된다. |

### UC-AI-04. AI의 인간형 플레이

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | AI의 인간형 플레이 |
| 액터 | AI 시스템 참가자 |
| 시작 조건 | AI 대전 세션이 `IN_PROGRESS`이고 처리 가능한 활성 단어가 있음 |
| 트리거 | AI가 목표 단어를 선택함 |
| 기본 흐름 | 1. AI가 난이도 프로필에 따라 인지 시간과 타이핑 시간을 계산한다.<br>2. 서버 내부 AI의 구조적 이점을 줄이기 위해 가상 전달·제출 지연을 포함한다.<br>3. 오타, 수정, 포기 여부를 시드 기반 난수로 결정한다.<br>4. 예상 제출 시각이 단어 바닥 도달 이전인지 확인한다.<br>5. AI는 한 번에 하나의 단어만 실제로 타이핑하고, 완료 시 사람과 같은 공통 판정 함수를 호출한다. |
| 대안 흐름 | **3A** 오타 후 포기 확률에 해당하면 해당 단어를 포기하고 다음 목표를 선택한다.<br><br>**4A** 예상 완료 시각이 바닥 도달 이후이면 제출하지 않고 다른 단어를 탐색한다.<br><br>**5A** 현재 목표가 사용자에 의해 먼저 제거되면 예약 작업을 취소하고 새 목표를 선택한다. |
| 종료 조건 | AI가 즉시 정답을 제출하지 않고, 난이도별 차이와 인간형 실수를 보이며 정상 게임 규칙을 따른다. |

### UC-AI-05. 사용자 연결 끊김 및 연습 재개

> 화장실을 다녀오거나 새로고침이 오래 걸리는 정상적인 경우까지 게임에서
> 쫓아내는 부작용을 피하기 위해, PvP·AI 연습전 모두 강제 탈락 유예 타이머를 두지 않는다.
> `PAUSED` 상태·`MatchClock`·30초 유예·정지 횟수 제한은 구현 범위에서 제외됐다.

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | 사용자 연결 끊김 및 연습 재개 |
| 액터 | 사용자, 서버 |
| 시작 조건 | AI 대전 세션이 `IN_PROGRESS`이고 사용자 소켓이 끊김 |
| 트리거 | 네트워크 단절 또는 브라우저 새로고침 |
| 기본 흐름 | 1. 서버는 세션을 일시정지하지 않는다 — 단어 스폰, AI 입력, 경기 종료 시계가 그대로 진행된다.<br>2. AI는 계속 단어를 지우며 진행하고, 낙하한 단어의 스플래시 데미지도 계속 적용된다(끊긴 사용자도 계속 맞을 수 있다 — 자연스러운 페널티).<br>3. 사용자가 아무 때나 같은 `roomId`로 `join_room`을 재전송하면 서버가 `state_sync`(HP, 활성 단어, 남은 시간)로 즉시 복구시켜준다.<br>4. 재접속 시 카운트다운 없이 바로 진행 중인 매치에 합류한다. |
| 대안 흐름 | **1A** 매치 자체가 `MATCH_DURATION_MS`(180초) 하드 타임아웃을 가지므로, 사용자가 끝까지 재접속하지 않아도 매치는 정상적으로 `TIME_LIMIT` 또는 `KO`로 종료된다.<br><br>**4A** 재접속하지 못한 채 매치가 끝나면 결과는 `winnerId` 확정 여부에 따라 `FINISHED`/`ABORTED`로 저장되고(§3.1), `ABORTED`는 population-default 통계(§6.9)에서 제외된다. |
| 종료 조건 | 같은 상태에서 정상 재개되거나 경쟁 기록에 영향을 주지 않는 중단 결과가 생성된다. |

### UC-AI-06. AI 대전 정상 종료 및 결과 확인

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | AI 대전 정상 종료 및 결과 확인 |
| 액터 | 사용자, 서버 |
| 시작 조건 | 세션이 `IN_PROGRESS` 상태 |
| 트리거 | 사용자 또는 AI HP가 0 이하가 되거나 180초가 경과함 |
| 기본 흐름 | 1. 서버가 세션 종료를 원자적으로 확정한다.<br>2. 모든 단어 스폰, AI 예약 작업, 바닥 판정 타이머를 중지한다.<br>3. 승리·패배·무승부와 종료 사유를 계산한다.<br>4. 연습 기록을 멱등 저장한다.<br>5. 사용자에게 `match_end`와 결과 통계를 전송한다.<br>6. 결과 화면을 표시한다. |
| 대안 흐름 | **1A** 동일 이벤트 처리 중 양쪽 HP가 동시에 0 이하가 되면 `DRAW`로 종료한다.<br><br>**4A** 동일 `matchId` 저장 요청이 재실행되면 기존 기록을 반환하고 중복 저장하지 않는다.<br><br>**5A** 결과 이벤트 전송에 실패해도 서버 종료 상태와 기록은 유지하며 재접속 시 결과를 다시 제공한다. |
| 종료 조건 | 세션이 한 번만 종료되고 연습 결과가 표시되며 모든 예약 작업이 정리된다. |

### UC-AI-07. 사용자의 연습 중단

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | 사용자의 연습 중단 |
| 액터 | 사용자 |
| 시작 조건 | AI 대전 세션이 `COUNTDOWN`, `IN_PROGRESS`, `PAUSED` 중 하나 |
| 트리거 | 사용자가 `연습 종료` 또는 `로비로`를 선택함 |
| 기본 흐름 | 1. 종료 확인 모달을 표시한다.<br>2. 사용자가 종료를 확인한다.<br>3. 서버가 세션을 `ABORTED`로 변경한다.<br>4. 모든 타이머와 AI 작업을 정리한다.<br>5. 완료되지 않은 연습으로 저장하거나 저장하지 않는 정책에 따라 처리한다.<br>6. 로비로 이동한다. |
| 대안 흐름 | **2A** 사용자가 취소하면 연습 화면으로 돌아간다.<br><br>**3A** 세션이 이미 정상 종료되었다면 종료 요청을 무시하고 결과 화면을 표시한다. |
| 종료 조건 | 세션 리소스가 정리되고 PvP 승패·랭킹에 영향을 주지 않는다. |

### UC-AI-08. 같은 난이도로 재연습

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | 같은 난이도로 재연습 |
| 액터 | 사용자 |
| 시작 조건 | 정상 종료 또는 중단 결과 화면이 표시됨 |
| 트리거 | 사용자가 `다시 연습`을 누름 |
| 기본 흐름 | 1. 서버가 이전 세션이 완전히 종료되고 잠금이 해제되었는지 확인한다.<br>2. 같은 난이도로 새 `roomId`, `matchId`, 난수 시드를 생성한다.<br>3. 이전 HP, 단어, 타이머, 통계를 참조하지 않는다.<br>4. 카운트다운 후 새 연습을 시작한다. |
| 대안 흐름 | **1A** 이전 세션 정리가 진행 중이면 짧게 대기 후 재시도한다.<br><br>**2A** 새 세션 생성에 실패하면 결과 화면에 머물며 재시도 버튼을 제공한다. |
| 종료 조건 | 이전 상태가 섞이지 않은 새 연습 세션이 시작된다. |

### UC-AI-09. AI 내부 오류 복구

| 항목 | 내용 |
|---|---|
| 유스케이스 이름 | AI 내부 오류 복구 |
| 액터 | 서버 |
| 시작 조건 | 연습 진행 중 AI 목표 선택, 난수 계산, 예약 작업에서 예외가 발생함 |
| 트리거 | AI 내부 처리 예외 |
| 기본 흐름 | 1. 해당 단어의 AI 행동만 포기한다.<br>2. 오류를 서버 로그와 메트릭에 기록한다.<br>3. 연속 오류 카운트를 증가시킨다.<br>4. 다음 스폰부터 정상 AI 판단을 계속한다. |
| 대안 흐름 | **3A** 연속 오류가 임계치를 넘으면 세션을 `VOID`로 종료한다.<br><br>**4A** 종료 시 사용자에게 서버 오류임을 안내하고 PvP 패배로 기록하지 않는다. |
| 종료 조건 | 단일 AI 오류가 서버 전체나 다른 연습 세션을 중단시키지 않는다. |

---

## 6. AI 행동 모델 및 운영값 (실제 구현 기준)

> 설계 당시에는 `perceptionMs`/`syllablesPerSecond`/`typoRate` 등을 난이도별 고정 상수 3벌로
> 두는 안이었지만, 실제 구현은 한 단계 더 나아가 **"실력 프로필(스킬) × 난이도 보정치"** 구조로
> 갔다 — 스킬 프로필 자체가 population-default 통계나 실제 유저의 과거 성적으로 개인화될 수
> 있기 때문이다(§6.9). 관련 코드: `src/game/player-model.ts`,
> `src/game/acid-rain/ai/ai-execution-profile.ts`, `ai-executor.ts`, `state-evaluator.ts`.

### 6.1 기본 원칙

- AI는 서버 내부 정답을 알고 있어도 즉시 제출하지 않는다.
- AI는 한 번에 하나의 단어만 실제로 타이핑한다(`AiExecutionTask` 1개).
- AI는 HP를 직접 변경하지 않는다 — 정답 제출은 사람과 동일한 `AcidRainService.submitWord()` 공통
  판정 함수를 통과한다.
- AI의 난수(`RandomSource`)와 시계(`Clock`)는 테스트에서 주입 가능하며, 시드를 고정하면 결정적으로
  재현된다(`ai-scheduler.spec.ts` 등에서 사용).

### 6.2 실력 프로필 → 실행 프로필 변환

```ts
// src/game/player-model.ts
DEFAULT_PLAYER_SKILL = { wpm: 45, accuracy: 0.92, reactionTimeMs: 650, sampleCount: 0, confidence: 0 };

DIFFICULTY_MODIFIERS = {
  BEGINNER: { speed: 0.85, accuracy: -0.08, reaction: 1.15 },
  NORMAL:   { speed: 1.00, accuracy:  0.00, reaction: 1.00 },
  HARD:     { speed: 1.15, accuracy:  0.08, reaction: 0.85 },
};

function toAiExecutionProfile(skill, difficulty) {
  return {
    typingWpm:      clamp(skill.wpm * modifier.speed, 20..140),
    accuracy:       clamp(skill.accuracy + modifier.accuracy, 0.7..0.98),
    reactionDelayMs: clamp(skill.reactionTimeMs * modifier.reaction, 250..2000),
  };
}
```

`skill`(`PlayerSkillProfile`)은 기본값(`DEFAULT_PLAYER_SKILL`)이거나, §6.9의 개인화 파이프라인이
실제 유저의 최근 매치 표본으로 산출한 값이다 — **난이도 보정치는 그 스킬 위에 곱/합산되는 배율일
뿐, 난이도 자체가 절대 수치를 고정하지 않는다.** 즉 같은 `HARD`라도 개인화된 상대 스킬에 따라
체감 난이도가 달라질 수 있다.

### 6.3 난이도별 실행 파라미터

`typingWpm`/`accuracy`/`reactionDelayMs`(§6.2, 개인화 대상) 외에, 아래는 순수 난이도로만
결정되는 고정 파라미터다(`DIFFICULTY_EXECUTION_CONFIG`, `ai-execution-profile.ts`):

| 파라미터 | Beginner | Normal | Hard |
|---|---:|---:|---:|
| 오타 수정 지연(`correctionDelayMs`) | 220ms | 150ms | 90ms |
| 단어 포기 확률(`abandonProbability`) | 12% | 6% | 2% |
| 반응 편차(`jitterMs`) | ±120ms | ±80ms | ±40ms |
| 오타 확률 하한(`typoFloor`) | 2% | 1% | 0.5% |
| 오타 확률 상한(`typoCeiling`) | 25% | 18% | 12% |

오타 확률은 `1 - accuracy`를 위 하한/상한으로 clamp해서 구한다(개인화된 `typoProbability` 표본이
있으면 그 값을 대신 clamp — §6.9). §6.2의 `abandonProbability`/`correctionDelayMs`도 개인화
표본이 있으면 이 표에 우선해 대체된다.

### 6.4 타이핑 실행 타임라인

```text
reactionEndsAtMs = selectedAtMs + max(1, reactionDelayMs + jitter)   // jitter = ±jitterMs 균등분포

// 이후 키스트로크 1개씩:
perKeystrokeMs = 60000 / (typingWpm * 5)
각 키스트로크마다 typoChance 확률로 오타 발생 → 발생 시 correctionDelayMs 지연 추가
```

단어를 목표로 선택하는 시점에 `abandonProbability` 확률로 그 단어 자체를 포기한다
(`AiExecutor.shouldAbandon`). 한글 입력은 2벌식 조합 상태를 실제로 시뮬레이션해
(`hangul-ime.ts`) `opponent_typing`에 오타/수정 과정이 그대로 드러난다 — 완성형 텍스트를
단순히 지연 후 통째로 제출하지 않는다.

### 6.5 게임 진행 단계와 AI 값의 관계

게임 자체는 온라인 대전과 동일하게 시간 경과에 따라 단어 스폰 간격·낙하 속도·단어 티어가
상승한다(`GAME_DESIGN.md` §3.3b/§3.4). AI 실행 프로필(§6.2/6.3)은 경기 시작 시 확정된 값을
끝까지 유지한다 — 경기 중 사용자의 실력에 맞춰 AI 수치를 몰래 바꾸는 로직은 없다(§6.7).

운영값은 단어를 목표로 선택하는 시점(`AiExecutor.createTask`)에 확정된다. 같은 단어를 타이핑하는
도중 게임 구간이 바뀌어도 이미 예약된 타임라인은 다시 계산하지 않는다.

### 6.6 목표 선택 (utility 기반, `state-evaluator.ts`)

```text
successProbability = clamp(예상 완료 시각이 landAt 이전일 가능성, 0, 1)
urgency             = clamp(1 - remainingMs / urgencyWindowMs, 0, 1)   // urgencyWindowMs = 3000ms
baseExpectedValue   = successProbability × (damageWeight × damage + urgencyWeight × urgency)
opportunityCost     = 이 단어를 고르면 놓치게 되는 다른 후보들의 기댓값
utility             = baseExpectedValue − opportunityCostWeight × opportunityCost
                       // damageWeight = urgencyWeight = 1, opportunityCostWeight = 0.25
```

완료 예상 시각이 `landAt`(바닥 도달 시각) 이후인 단어는 후보에서 제외(`eligible: false`)한다.
현재 타이핑 중인 목표를 다른 단어로 바꾸려면 새 후보의 utility가 현재 목표보다
`switchMargin`(0.1) 이상 높아야 한다 — 매 틱 사소한 차이로 목표가 자꾸 바뀌는(flip-flop)
것을 막는 히스테리시스. 이 모든 후보/결정 과정은 `ai_monitor_snapshot`
(`WEBSOCKET_PROTOCOL.md` §6.8)으로 그대로 노출되어 프론트에서 시각화할 수 있다.

### 6.7 적응 정책

MVP 설계 원칙 그대로, **경기 중** 사용자의 실시간 실력에 맞춰 AI 수치를 몰래 바꾸는 로직(고무줄
보정)은 없다 — 선택한 실행 프로필을 경기 끝까지 유지하고, 공통 게임 난이도 램프만 함께 적용된다.
다만 이는 §6.9의 개인화와는 다른 층위다: 개인화는 **매치 시작 전에** 그 유저의 과거 매치 이력으로
초기 스킬 프로필을 조정하는 것이지, 진행 중인 한 판 안에서 실시간으로 난이도를 바꾸는 것이
아니다.

### 6.9 개인화 파이프라인 (실제 구현, 설계 당시 문서에 없던 내용)

`backend#166`/`#176`에서 추가된, 실제 유저의 과거 데이터를 AI 실행 프로필에 반영하는 계층이다.

| 구성요소 | 파일 | 역할 |
|---|---|---|
| `PerformanceService` | `performance.service.ts` | 매치 중 각 참가자의 타건/정답 기록(`WordAttemptRecord`)을 수집·집계 |
| `TypeOrmPlayerPerformanceSource` | `player-performance-source.ts` | 특정 유저의 최근 매치 성능 표본(wpm/accuracy/reactionTimeMs) 조회 |
| `TypeOrmPlayerBehaviorSource` | `player-behavior-source.ts` | 오타/포기/단어 길이별 성향 등 더 세부적인 행동 표본 조회 |
| `PlayerPerformanceProfileProvider` | `ai/player-performance-profile-provider.ts` | 위 소스들을 조합해 `PlayerRuntimeProfile`을 만들고, `source`를 `DEFAULT`/`BLENDED`/`PERSONALIZED` 중 하나로 판정 |
| population-default 추정기 | `population-default.estimator.ts`, `population-default.config.ts`, `generate-population-default.ts` | 개인 표본이 없는 신규 유저를 위한 전체 유저 통계 기반 기본값. **수동 오프라인 스크립트**로만 생성되며 자동 실행되지 않는다 — `requireExplicitConsent: true` + 환경변수 allowlist + 수동 publication gate로 3중 방어 |

`source` 판정 기준(`player-performance-profile-provider.ts`):
- `sampleCount === 0` → `DEFAULT`(population-default 또는 정적 기본값)
- `0 < sampleCount < personalizedSampleThreshold` → `BLENDED`
- `sampleCount >= personalizedSampleThreshold` → `PERSONALIZED`(그 유저의 실제 최근 매치 데이터를
  직접 반영)

`typoProbability`/`abandonProbability`는 표본 수가 쌓일수록 자동으로 `available`/`confidence`가
올라가 실제로 활성화되지만, **`correctionDelayMs`와 단어 길이별 성향(`wordLengthPerformance`)은
현재 `player-behavior-source.ts`에서 항상 `null`/`0`으로 하드코딩돼 있다** — 표본이 쌓여도
저절로 채워지지 않고, 실제 관측 로직을 새로 구현해야 값이 생긴다(`backend#167`/`#168`).

이 판정 결과는 `ai_monitor_snapshot.profile.source`(`WEBSOCKET_PROTOCOL.md` §6.8)로 그대로
노출되어, 지금 이 AI가 기본값으로 도는지 개인화된 상대를 흉내 내는지 실시간으로 확인할 수 있다.

---

## 7. 서버 구조와 데이터 흐름

| 구성요소 | 책임 |
|---|---|
| `AcidRainService` | 공통 스폰, HP, 종료, 단어 상태 전이, 판정 |
| `AiPracticeService` | 연습 세션(로비) 생성, 난이도 선택, 활성 게임 잠금 |
| `AiScheduler` | 방별 AI 실행 상태 관리 — 목표 재평가, 타이핑 태스크 예약/취소, 스냅샷 발행 |
| `AiExecutor` | 실제 타이핑 타임라인 생성(§6.4) — 키스트로크별 오타/수정 시뮬레이션 |
| `state-evaluator.ts`(모듈) | 목표 선택 utility 계산(§6.6) |
| `PlayerPerformanceProfileProvider` | 개인화 프로필 로딩(§6.9) |
| `PerformanceService` | 매치 중 타건/정답 기록 수집, 매치 종료 후 개인화 소스에 반영할 표본 저장 |

`AiOpponentService`/`SeededRandom`/`AiMetrics`라는 이름의 별도 클래스는 없다 — 위 컴포넌트들로
역할이 나뉘어 구현됐다.

### 7.1 핵심 판정 진입점

```ts
AcidRainService.submitWord(
  { roomId, playerId, wordId, text, attemptId },
  server, // Socket.IO Server — 결과를 즉시 룸에 브로드캐스트하기 위해 필요
);
```

- 같은 `attemptId` 재전송은 멱등 처리한다(`processedAttempts` 캐시, TTL 존재).
- 새 `attemptId`는 같은 단어에 대한 새 입력 시도로 처리한다.
- 단어 상태는 `ACTIVE → CLEARED` 또는 `ACTIVE → MISSED` 중 하나만 가능하다.
- AI도 동일한 이 함수를 호출한다(`AiScheduler`의 `registerRoom({ submitWord: (input) =>
  this.submitWord(input, server) })`) — 사람과 완전히 같은 판정 경로를 탄다.

### 7.2 AI 스케줄러 상태(실제 필드)

```ts
// ai-scheduler.ts SchedulerState (개념 요약, 실제는 registration 필드도 포함)
interface SchedulerState {
  roomId: string;
  aiParticipantId: string;
  modelPlayerId: string;      // 개인화 프로필을 조회할 실제 유저 ID
  difficulty: AiDifficulty;
  generation: number;         // 타이핑 태스크 세대 번호 — 무효화 기준(§7.3)
  lastStateVersion: number;
  paused: boolean;            // pause()/resume() 메서드는 존재하지만 현재 아무 곳에서도 호출되지 않음
  destroyed: boolean;
  profileSnapshot: PlayerSkillProfile;
  runtimeProfile: PlayerRuntimeProfile;
}
```

세션 자체의 `PAUSED` 상태(§3.1)와 `SchedulerState.paused`는 다른 개념이다 — 후자는 메서드로만
존재하고 실제로 호출되는 지점이 없어(§3.1 참고) 사실상 미사용 상태다.

### 7.3 타이핑 태스크 무효화

예약된 키스트로크 타임아웃이 실행되기 직전, `AiExecutor`/`AiScheduler`가 다음을 확인한다.

```text
task.generation === state.generation   // 이 태스크가 여전히 최신 세대인지
!state.destroyed
word.status === 'ACTIVE'               // 사람이 먼저 지웠거나 이미 바닥에 닿지 않았는지
```

목표가 바뀌거나(§6.6 switchMargin 조건 충족) 세션이 끝나면 `state.generation`을 증가시켜 오래된
콜백을 무효화한다. `AcidRainService.finalizeMatch()`에서 `this.aiScheduler.destroy(roomId)`를
호출해 매치 종료 시 해당 방의 스케줄러 상태를 정리한다.

---

## 8. WebSocket 최소 확장안

### 8.1 로비 Client → Server

> 아래는 실제 구현(`lobby.gateway.ts`)과 일치한다 — §0(로비 프로토콜)의 `{ type, payload, seq }`
> envelope을 그대로 따른다.

| Type | Payload | 설명 |
|---|---|---|
| `CREATE_AI_PRACTICE` | `{ requestId, difficulty }` | 비공개 AI 대전 세션 생성 |
| `GET_ACTIVE_AI_PRACTICE` | `{}` | 재접속 또는 중복 요청 시 활성 세션 조회 |
| `CANCEL_AI_PRACTICE` | `{ roomId? }` | **설계안에 없던 이벤트** — 진행 중인 AI 연습 세션을 취소 |

### 8.2 로비 Server → Client

| Type | Payload | 설명 |
|---|---|---|
| `AI_PRACTICE_CREATED` | `{ roomId, mode, difficulty, participants: ParticipantPublic[], expiresAt }` | 연습 세션 생성 완료(또는 `GET_ACTIVE_AI_PRACTICE` 응답). 설계안의 `matchId` 필드는 없다 — `roomId`가 곧 매치 식별자 역할을 겸한다 |
| `AI_PRACTICE_REJECTED` | `{ code, message }` | 잘못된 난이도, 활성 게임 존재(`ACTIVE_AI_PRACTICE_EXISTS`), 세션 없음(`AI_PRACTICE_NOT_FOUND`) 등 |

### 8.3 게임 이벤트

`/game` 네임스페이스는 PvP와 완전히 동일한 이벤트 계약을 그대로 재사용한다(`WEBSOCKET_PROTOCOL.md`
§6.3) — AI 연습전만을 위한 별도 이벤트는 `opponent_typing`의 IME 확장과 `ai_monitor_snapshot`
(§6.8) 두 가지뿐이며, 이 둘도 AI 참가자가 있을 때만 발생할 뿐 이벤트 이름 자체는 공용이다.
`ParticipantPublic`의 실제 필드는 `{ participantId, userId?, nickname, type: 'HUMAN'|'AI',
aiDifficulty?, avatar? }` — 설계안의 `PlayerPublic`/`playerId`/`playerType`이라는 이름은 실제로
쓰인 적이 없다(`WEBSOCKET_PROTOCOL.md` §6.3 참고).

AI는 가짜 사용자 계정을 요구하지 않으며, 친구·프로필·랭킹 대상에서 제외된다.

---

## 9. 전적과 통계 정책

### 9.1 저장 원칙 (실제 구현)

AI 대전은 개인 기록으로 저장되지만 `User.wins`/`User.losses`/PvP 랭킹에는 반영하지 않는다. 아래
예시 JSON은 원래 설계안의 "권장 구조"였고, 실제 저장 스키마는 이 문서가 예상한 것과 이름이
다르다 — 상세 컬럼은 `DATABASE_MODELING.md`/`DATABASE_DESIGN.md`를 정본으로 하고, 여기서는
AI 관련 차이만 짚는다.

- `MatchHistory.mode`(`MatchMode` enum: `'PVP' | 'AI_PRACTICE'`)로 PvP와 구분한다 — 설계안의
  예상과 값 자체는 일치한다.
- 설계안의 `MatchResult`(`HUMAN_WIN`/`AI_WIN`/`DRAW`/`ABORTED`/`VOID`) 같은 단일 필드는 없다.
  대신 `MatchHistory.winner`(nullable FK)로 승자를 표현하고, 참가자별 결과는
  `MatchParticipant.rank`로, 개인 성능 기록의 데이터 품질은
  `ParticipantPerformance.resultStatus`(`'FINISHED' | 'ABORTED' | 'VOID'`, §3.1)로 나눠서
  표현한다.
- AI 참가자를 위해 실제 `User` 행을 생성하지 않는다는 원칙은 그대로 유지된다
  (`ParticipantPublic.type === 'AI'`는 `userId`가 없다).
- 세부 수치(`clearedWords`/`attempts`/`avgReactionMs` 등)는 `WordAttemptRecord`/
  `KeystrokeRecord`/`ParticipantPerformance` 테이블에 개별 레코드로 쌓인다 — 하나의 JSON blob이
  아니라 정규화된 테이블 구조다.

### 9.2 정확도 정의

```text
accuracy = acceptedCorrectAttempts / totalSubmissionAttempts
```

`ABORTED`와 `VOID`는 PvP 승패에 반영하지 않으며, 개인 연습 기록에서도 별도 상태로 구분한다.

### 9.3 멱등 저장

`matchId`에 UNIQUE 제약을 두고 같은 세션의 종료 결과가 두 번 저장되지 않도록 한다.

---

## 10. 예외 및 공정성 규칙

- 같은 텍스트의 활성 단어를 동시에 두 개 이상 스폰하지 않는다.
- AI는 한 번에 하나의 단어만 실제로 타이핑한다.
- AI의 서버 내부 구조적 이점을 가상 전달·제출 지연으로 보정한다.
- AI는 클라이언트에서 동작하지 않으며 사용자가 AI 난이도, 제출 시각, HP를 조작할 수 없다.
- 사용자당 활성 게임은 하나만 허용한다.
- 여러 탭 중 하나만 끊긴 경우에는 일시정지하지 않는다.
- 일시정지는 경기당 최대 2회, 누적 최대 60초로 제한한다.
- 모든 방별 상태와 타이머는 다른 방과 격리한다.
- 서버 재시작 시 타이머 자체를 저장하지 않고 활성 단어와 남은 시간으로 다시 계산한다.
- 정상 종료 후 살아 있는 AI 예약 작업이 없어야 한다.

---

## 11. 테스트 및 완료 기준

### 11.1 유스케이스 테스트

- AI 대전 진입부터 결과 화면까지 사용자 한 명으로 완주할 수 있다.
- 잘못된 난이도, 중복 클릭, 여러 탭, 활성 게임 존재 시 새 세션이 중복 생성되지 않는다.
- AI와 사용자가 같은 단어를 제출해도 최초 유효 제출만 승인된다.
- 오답 제출 후 새 `attemptId`로 수정 제출할 수 있다.
- 사용자 연결이 완전히 끊기면 시계와 AI가 함께 멈춘다.
- 재접속 시 남은 낙하 시간과 경기 시간이 보존된다.
- 재접속 제한 초과 시 `ABORTED`가 되며 PvP 승패에 반영되지 않는다.
- 재대전 시 이전 HP, 단어, 통계, 타이머가 남지 않는다.
- 단일 AI 내부 오류가 다른 단어와 다른 방에 영향을 주지 않는다.

### 11.2 AI 행동 테스트

- 같은 시드와 같은 입력 이벤트에서 동일한 AI 판단을 재현한다.
- Hard의 평균 반응 시간이 Normal보다 빠르고, Normal이 Beginner보다 빠르다.
- Beginner의 오타·포기율이 Normal보다 높고, Normal이 Hard보다 높다.
- AI가 한 번에 두 단어를 동시에 제출하지 않는다.
- AI가 정답을 0ms에 제출하지 않는다.
- AI가 실제 플레이테스트에서 사용자를 이기는 사례가 존재한다.
- AI가 100% 정확도나 항상 같은 반응 시간을 보이지 않는다.

### 11.3 밸런스 검증

자동 시뮬레이션은 기준 사용자 봇을 정의한 뒤 난이도별 최소 100회를 수행한다.

| 기준 사용자 | 예시 프로필 |
|---|---|
| 초보 | 낮은 입력 속도, 높은 오타율, 긴 반응 시간 |
| 평균 | 중간 입력 속도, 보통 정확도, 중간 반응 시간 |
| 숙련 | 높은 입력 속도, 높은 정확도, 짧은 반응 시간 |

승률 범위는 공식 합격 기준이 아니라 내부 밸런스 목표로 문서화한다. 경기 중 HP를 임의로 조작해 승률을 맞추지 않는다.

### 11.4 Definition of Done

- [ ] 로비에서 AI 대전을 상시 선택하고 한 판을 완주할 수 있다.
- [ ] 온라인 매칭 지연 시 AI 대전으로 안전하게 전환할 수 있다.
- [ ] AI 실력 선택 화면에서 Beginner·Normal·Hard를 선택할 수 있다.
- [ ] 별도 레벨업·해금·미션 시스템이 존재하지 않는다.
- [ ] 연습 모드임이 UI에 명확히 표시된다.
- [ ] AI 대전 결과가 PvP 랭킹과 승패에 반영되지 않는다.
- [ ] 세 난이도가 실제 행동 차이를 보인다.
- [ ] AI가 반응 편차, 오타, 수정, 포기를 보인다.
- [ ] AI가 실제 플레이에서 사용자를 이길 수 있다.
- [ ] AI는 한 번에 하나의 단어만 타이핑한다.
- [ ] AI 제출은 사람과 동일한 판정 함수를 통과한다.
- [ ] 연결 끊김, 중단, 재접속, 오류, 재대전이 안전하게 처리된다.
- [ ] 종료 후 남은 AI 타이머와 활성 세션 잠금이 없다.
- [ ] 단위·통합·밸런스 테스트 결과가 저장소에 남아 있다.
- [ ] README와 게임·WebSocket·DB·유스케이스 문서가 실제 구현과 일치한다.
- [ ] 팀원이 평가에서 AI 판단 모델과 연습 모드 정책을 설명할 수 있다.

---

## 12. 구현 작업 분해

| 순서 | 작업 | 선행 조건 |
|---:|---|---|
| 1 | 공통 산성비 엔진과 단어 상태 전이 구현 | 없음 |
| 2 | 제출 `attemptId`와 방 단위 직렬 판정 구현 | 1 |
| 3 | AI 대전 세션 생성·잠금·상태 머신 구현 | 1 |
| 4 | 난이도 프로필과 시드 난수 구현 | 1 |
| 5 | 목표 선택·반응 시간·오타·포기 구현 | 4 |
| 6 | AI 예약 작업 생성·취소·일시정지·재개 구현 | 3, 5 |
| 7 | 프론트 AI 대전 진입·실력 선택·결과 UI 구현 | 3 |
| 8 | 연결 끊김·복귀·중단·재대전 구현 | 6, 7 |
| 9 | AI 대전 기록 스키마와 PvP 통계 제외 정책 구현 | 3 |
| 10 | 단위·통합·밸런스 테스트 및 수치 조정 | 1~9 |
| 11 | README, GAME_DESIGN, WEBSOCKET_PROTOCOL, DATABASE_DESIGN, USE_CASES 갱신 | 1~10 |

---

## 13. 구현 전 팀 합의 항목

1. AI 대전 기록을 별도 테이블로 둘지 기존 `MatchHistory`에 `mode`를 추가할지 결정한다. 권장: 기존 전적에 `mode`, `result`, `aiDifficulty`를 추가하되 PvP 통계에서는 제외한다.
2. 중단된 연습(`ABORTED`)을 개인 기록 목록에 노출할지 결정한다.
3. 결과 화면에서 틀린 단어와 추천 난이도를 제공할지 결정한다.
4. MVP에서 세 AI 실력을 모두 제공할지, Normal을 먼저 완성한 뒤 확장할지 결정한다.
5. 한글 입력 시간을 음절 수로 근사할지 예상 타건 수까지 계산할지 결정한다.

---

## 14. 평가 시 설명 요약

> AI 대전은 온라인 상대가 없어도 언제든 플레이할 수 있는 상시 1인 대전입니다. 온라인 대전과 동일한 규칙·화면·시간별 게임 난이도 상승을 사용하고, 사용자는 시작 전에 상대 AI의 실력만 Beginner·Normal·Hard 중에서 선택합니다. 세 개의 별도 모델이 아니라 하나의 목표 선택 알고리즘에 인지 시간, 입력 속도, 오타와 포기 확률 설정값을 다르게 적용합니다. AI는 활성 단어의 남은 시간, 예상 데미지, 성공 가능성을 비교해 목표를 선택하고, 한 번에 하나의 단어만 타이핑하며 사람과 같은 서버 판정 함수를 통과합니다. AI전 결과는 PvP 승패와 리더보드에는 반영하지 않습니다.
