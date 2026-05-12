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
