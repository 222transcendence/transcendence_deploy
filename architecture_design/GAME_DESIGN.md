# Game System & Phase Design

## 1. Battle Phase State Machine
배틀은 엄격한 순차적 페이즈로 관리되며, 모든 플레이어의 액션이 완료되어야 다음 페이즈로 전이됨.

| Phase | Description | Sync Actions |
| :--- | :--- | :--- |
| **DRAW** | 각 플레이어에게 카드 지급 (최대 5장) | `CARDS_DRAWN` |
| **MOVE** | 이동 카드 제출 및 거리 계산, 선공 결정 | `MOVE_SUBMITTED`, `DISTANCE_CHANGED` |
| **ATTACK** | 공격 카드 제출 및 필살기 트리거 체크 | `ATTACK_DECLARED` |
| **DEFENSE** | 방어 카드 제출 및 주사위 연산 | `DEFENSE_SUBMITTED` |
| **RESULT** | 데미지 적용 및 상태이상 턴 감소 | `DAMAGE_APPLIED`, `TURN_END` |

## 2. Core Mechanics
### 2.1. Dice Engine (The "33.3%" Rule)
- **Logic**: 모든 주사위는 독립 시행.
- **Formula**: `DiceCount = (Base Stat + Card Values + Skill Buffs)`
- **Success**: 주사위 1개당 1/3(약 33.3%) 확률로 앞면 판정. 서버 로직에서 `random.randint(1, 3) == 1`로 처리.

### 2.2. Initiative (선공권)
- 이동 페이즈에서 제출된 이동 카드의 합계가 높은 플레이어가 획득.
- 합계가 같을 경우 50% 확률로 서버가 결정.

### 2.3. Status Effects (상태이상)
- **Stacking**: 중복 적용 시 리스트 형태로 관리.
- **Processing**: 이동 페이즈 종료 후(독, 재생 등) 또는 결과 페이즈 종료 후(자괴 등) 연산 수행.

## 3. Skill System (Trigger-Action)
- **Trigger**: 특정 페이즈 + 특정 카드 조합 (예: 근거리 공격 + 특수 2장).
- **Action**: 공격력 가산, 카드 파괴, 상태이상 부여 등.

## 4. 현재 backend 구현(`feat/P3-02-P3-03-game-engine`, in review)과의 차이
P3-02/P3-03 PR 코드를 직접 확인한 결과, 위 설계 문서가 가정하는 실시간 sync action(`CARDS_DRAWN`,
`MOVE_SUBMITTED`, `DISTANCE_CHANGED`, `ATTACK_DECLARED`, `DEFENSE_SUBMITTED`, `DAMAGE_APPLIED`,
`TURN_END` 등)은 아직 구현되어 있지 않음. 실제로는:
- WebSocket/Socket.io 게이트웨이 없이 **순수 REST + Redis** 구조 (`POST /game/rooms`,
  `/game/rooms/:id/join`, `/game/rooms/:id/submit`, `GET /game/rooms`만 존재).
- 방 단건 상태를 조회하는 GET 엔드포인트가 없어, 상대방이 카드를 제출했는지/페이즈가 바뀌었는지
  알 수 있는 방법이 클라이언트에 없음.
- `submitCards` 응답에 최종 HP만 반영되고, 주사위 성공 횟수·데미지 분해·스킬 발동 여부 등
  애니메이션에 필요한 중간 연산 값이 노출되지 않음.
- `Character.skills` 필드는 엔티티에 존재하지만 트리거 로직(`Skill System`)은 아직 미구현.

후속 정리는 `transcendence_backend` 신규 이슈([P3-0X] 게임 상태 조회/실시간 푸시 및 액션 디테일
노출 보강)에서 추적함.

## 5. Frontend Animation Hooks (P3-11, [#6](https://github.com/222transcendence/transcendence_frontend/issues/6))
위 백엔드 갭으로 인해 실데이터 연동 없이, 애니메이션 컴포넌트만 먼저 구현함
(`transcendence_frontend` `feature/6-phase-result-animations` 브랜치, `/dev/phase-animations`
데모 라우트 — 실제 게임 페이지(`/game/:roomId`, [#5](https://github.com/222transcendence/transcendence_frontend/issues/5))에는
아직 연결되지 않음).

| 컴포넌트 | 위치 | Props |
| :--- | :--- | :--- |
| `PhaseBanner` | `src/components/game/PhaseBanner.tsx` | `phase: GamePhase` |
| `DiceRollAnimation` | `src/components/game/DiceRollAnimation.tsx` | `result: DiceRollResult`, `onComplete?` |
| `DamageFloatingNumber` | `src/components/game/DamageFloatingNumber.tsx` | `popup: DamagePopup`, `onDone` |
| `SkillEffectOverlay` | `src/components/game/SkillEffectOverlay.tsx` | `trigger: SkillEffectTrigger`, `onDone` |
| `GameEndModal` | `src/components/game/GameEndModal.tsx` | `summary: MatchSummary`, `isWinner`, `onRematch`, `onBackToLobby` |

타입은 `src/types/gameAnimation.ts`에 정의. `DiceRollResult.success`, `DamagePopup.amount`,
`SkillEffectTrigger`는 현재 backend 응답에 없는 값이라 #5 게임 보드 UI와 백엔드 갭 이슈가
해결된 뒤, 실제 응답 필드로 매핑하는 작업이 별도로 필요함.
