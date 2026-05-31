# Frontend UI Design Guide — Transcendence TCG

피그마 메이크로 제작된 **Battle Arena & Deck Lobby** 예시 프로젝트를 레퍼런스로 삼아,  
`transcendence_frontend`에 적용할 UI/UX 설계 지침을 정리한 문서입니다.

---

## 1. 레퍼런스 프로젝트 개요

| 항목 | 내용 |
|---|---|
| 경로 | `222transcendence/Battlearenaanddecklobby` |
| 스택 | React 18 · Vite · Tailwind CSS v4 · shadcn/ui · Radix UI · Lucide React |
| 화면 | **BATTLE** (전투 아레나) / **LOBBY** (덱 빌더) 두 화면 전환 구조 |
| 특징 | 어두운 SF/판타지 다크 테마, 모노스페이스 폰트 기반 게임 UI |

이 레퍼런스의 **색상 토큰, 타이포그래피, 컴포넌트 패턴**을 transcendence 프로젝트에 그대로 적용합니다.

---

## 2. 기술 스택 설정

레퍼런스와 동일한 스택을 현재 `transcendence_frontend`에 추가해야 합니다.

```bash
npm install tailwindcss @tailwindcss/vite
npm install lucide-react
npm install @radix-ui/react-dialog @radix-ui/react-tabs @radix-ui/react-progress \
  @radix-ui/react-scroll-area @radix-ui/react-tooltip @radix-ui/react-separator
npm install class-variance-authority clsx tailwind-merge
npm install motion   # 애니메이션 (선택)
npm install react-router  # 페이지 라우팅
```

`vite.config.ts`에 Tailwind 플러그인 등록:

```ts
import tailwindcss from '@tailwindcss/vite'
export default { plugins: [react(), tailwindcss()] }
```

---

## 3. 디자인 토큰 (색상 & 타이포그래피)

레퍼런스의 `theme.css`에서 가져온 **다크 모드 CSS 변수**를 그대로 사용합니다.

### 3.1 색상 팔레트

```css
/* src/styles/theme.css */
.dark {
  --background:  #080c14;   /* 최심층 배경 */
  --card:        #0d1220;   /* 카드/패널 배경 */
  --secondary:   #131c30;   /* 보조 배경 */
  --muted:       #101828;   /* 흐린 배경 */

  --primary:     #00c9a7;   /* 메인 강조색 (틸) */
  --accent:      #ff3d5a;   /* 위험/적 강조색 (레드) */

  --foreground:       #d8e0f0;
  --muted-foreground: #4e5e80;
  --border:           rgba(255,255,255,0.07);
}
```

| 역할 | 색상 | 사용처 |
|---|---|---|
| Primary (틸) | `#00c9a7` | 내 플레이어 UI, 선택 링, 버튼, 승리 |
| Accent (레드) | `#ff3d5a` | 적 플레이어 UI, 위험, 파괴 |
| 배경 | `#080c14` | 전체 배경 |
| 카드 | `#0d1220` | 패널, 카드 뒷면 |
| 보더 | `rgba(255,255,255,0.07)` | 구분선 |

### 3.2 폰트

```css
@theme {
  --font-display: "Rajdhani", "Impact", sans-serif;  /* 제목, 버튼 */
  --font-sans:    "Inter", system-ui, sans-serif;    /* 본문 */
  --font-mono:    "JetBrains Mono", "Consolas", monospace; /* 수치, 로그 */
}
```

Google Fonts에서 `Rajdhani`(400, 600, 700), `JetBrains Mono`(400, 700) 로드.

### 3.3 희귀도 색상 (카드 등급)

레퍼런스의 rarity 시스템을 그대로 사용합니다.

| 등급 | 보더 색 | 텍스트 색 | 글로우 |
|---|---|---|---|
| C (일반) | `border-slate-600/70` | `text-slate-400` | 없음 |
| UC (비일반) | `border-emerald-600/70` | `text-emerald-400` | 약한 녹색 |
| R (레어) | `border-blue-500/70` | `text-blue-400` | 약한 파란색 |
| UR (울트라레어) | `border-purple-500/80` | `text-purple-400` | 보라색 글로우 |

---

## 4. 반응형 디자인 필수 요건

> **모든 화면은 반드시 반응형으로 구현해야 합니다.**  
> 레퍼런스는 데스크톱 고정 레이아웃이었지만, 본 프로젝트는 모바일·태블릿·데스크톱을 모두 지원해야 합니다.

### 4.1 브레이크포인트 기준 (Tailwind 기본값 사용)

| 이름 | 최소 너비 | 대상 기기 |
|---|---|---|
| `sm` | 640px | 세로 태블릿, 큰 모바일 |
| `md` | 768px | 가로 태블릿 |
| `lg` | 1024px | 노트북, 작은 데스크톱 |
| `xl` | 1280px | 일반 데스크톱 (레퍼런스 기준 크기) |

### 4.2 화면별 반응형 전략

#### 전투 화면 (Battle Arena)

- **모바일** (`< md`): 상단 적 정보 → 중앙 전장 → 하단 손패 순서로 **세로 스크롤** 없이 단일 열로 쌓기.  
  손패 카드는 가로 스크롤(`overflow-x: auto`)로 처리.
- **태블릿** (`md ~ lg`): 2행 구조. 상단(적 + 전장), 하단(내 캐릭터 + 손패).
- **데스크톱** (`>= lg`): 레퍼런스처럼 `grid-rows-[28%_28%_44%]` 3행 분할.

```
모바일                 태블릿                 데스크톱
┌──────────────┐      ┌──────────────────┐   ┌──────────────────┐
│  적 정보      │      │  적 정보  │ 전장  │   │  적 정보(28%)    │
│  전장 VS      │      │──────────────────│   │──────────────────│
│  배틀 로그    │      │  플레이어 │ 로그  │   │  전장 + 로그(28%)│
│  내 캐릭터    │      │  손패               │   │──────────────────│
│  손패 (가로스크롤) │  └──────────────────┘   │  플레이어 + 손패(44%)│
└──────────────┘                              └──────────────────┘
```

#### 덱 빌더 화면 (Deck Builder / Lobby)

- **모바일**: 탭 방식으로 [컬렉션 / 내 덱 / 프로필] 전환.  
  사이드바 네비게이션은 하단 탭바(`fixed bottom-0`)로 변환.
- **태블릿**: 2열 (`컬렉션 | 덱`). 네비게이션은 상단 탭.
- **데스크톱**: 레퍼런스처럼 `grid-cols-[220px_1fr_280px]` 3열.

```
모바일                 태블릿                 데스크톱
┌──────────────┐      ┌────────┬─────────┐  ┌────┬──────────┬────┐
│  [탭: 컬렉션] │      │컬렉션  │  내 덱  │  │사이│ 컬렉션   │ 덱 │
│  카드 목록    │      │        │         │  │드바│ 그리드   │    │
│  (그리드)     │      └────────┴─────────┘  └────┴──────────┴────┘
├──────────────┤
│ 하단 탭바     │
└──────────────┘
```

#### 카드 크기 반응형

```tsx
// CardTile 컴포넌트에서 크기를 화면에 맞게 동적 조정
const cardSizeClass = {
  mobile:  "w-[70px]  h-[94px]",
  tablet:  "w-[88px]  h-[120px]",
  desktop: "w-[108px] h-[150px]",
}
```

---

## 5. 화면(페이지) 구조

### 5.1 전체 라우팅 구조

```
/                     로그인 화면 (비인증 진입점)
/register             회원가입
/lobby                메인 로비 (덱 빌더 + 매칭 대기)
  /lobby/deck         덱 편성 탭
  /lobby/collection   카드 컬렉션 탭
  /lobby/profile      프로필 / 전적 탭
/battle/:matchId      전투 화면 (실시간 WebSocket)
/result/:matchId      전투 결과 화면
/replay/:matchId      리플레이 뷰어
```

### 5.2 공통 레이아웃 컴포넌트

레퍼런스의 헤더 구조를 따릅니다.

```tsx
// 공통 TopBar
<header className="h-11 flex items-center justify-between px-5 border-b border-border bg-card/70 backdrop-blur-sm">
  <Logo />               {/* CARD ARENA 로고 + 틸 도트 */}
  <NavTabs />            {/* BATTLE / LOBBY 전환 버튼 */}
  <StatusBar />          {/* 라운드 정보 + LIVE 배지 */}
</header>
```

모바일에서는 NavTabs를 **하단 탭바**(`fixed bottom-0 w-full`)로 이동.

---

## 6. 핵심 컴포넌트 설계

### 6.1 ActionCard (액션 카드)

레퍼런스 `CardTile`을 기반으로, 게임 명세서의 카드 타입에 맞게 확장합니다.

```ts
type ActionCardType = "move" | "attack_melee" | "attack_ranged" | "defense" | "special"
// 보라색(이동) / 붉은검(근거리) / 초록총(원거리) / 파란방패(방어) / 노란별(특수)

interface ActionCard {
  id: string
  type: ActionCardType
  topValue: number      // 위 방향 수치 (유효면)
  bottomValue: number   // 아래 방향 수치 (무효면)
  isFlipped: boolean    // 카드 방향
  rarity: "C" | "UC" | "R" | "UR"
}
```

**카드 방향 표시**: 카드 상단/하단을 시각적으로 구분. 유효 방향은 밝게, 무효 방향은 어둡게.

### 6.2 StatBar (HP/이동력 바)

레퍼런스 `StatBar`와 동일한 구조:

```tsx
<StatBar label="HP" value={87} max={127} color="bg-emerald-500" />
<StatBar label="MOV" value={3}  max={5}  color="bg-blue-500" />
```

### 6.3 StatusBadge (상태이상)

게임 명세서의 상태이상 7종을 뱃지로 표시합니다.

| 상태이상 | 아이콘 | 색상 |
|---|---|---|
| ATK/DEF/MOV 상승 | `TrendingUp` | `text-emerald-400` |
| ATK/DEF/MOV 저하 | `TrendingDown` | `text-orange-400` |
| 마비 | `Zap` (X) | `text-yellow-300` |
| 독 | `Skull` | `text-purple-400` |
| 재생 | `Heart` | `text-green-400` |
| 자괴 | `Timer` | `text-red-500` |
| 불사 | `Shield` (특수) | `text-cyan-300` |
| 봉인 | `Lock` | `text-slate-400` |

### 6.4 PhaseIndicator (페이즈 표시)

현재 배틀 페이즈를 상단에 표시합니다.

```
DRAW → MOVE → ATTACK → DEFENSE → RESULT
```

```tsx
const PHASES = ["DRAW", "MOVE", "ATTACK", "DEFENSE", "RESULT"] as const
// 각 페이즈는 font-mono tracking-widest 텍스트로 표시
// 현재 페이즈는 text-primary, 나머지는 text-muted-foreground
```

### 6.5 BattleLog (배틀 로그)

레퍼런스 구현을 그대로 사용합니다.

```tsx
<div className="h-[130px] rounded border border-border bg-card overflow-y-auto p-2 flex flex-col-reverse gap-[3px]">
  {log.map((entry, i) => (
    <p key={i} className={`text-[9px] font-mono leading-[1.7] ${
      i === 0 ? "text-primary font-bold" : "text-muted-foreground"
    }`}>{entry}</p>
  ))}
</div>
```

모바일에서는 **접기/펼치기** 토글로 공간 절약.

### 6.6 DiceResult (주사위 결과 표시)

서버에서 계산된 주사위 결과를 시각적으로 표현합니다.

```
공격 주사위: ⬤ ⬤ ○ ○ ⬤  → 성공 3 / 실패 2
방어 주사위: ⬤ ○ ○ ⬤    → 성공 2 / 실패 2
최종 데미지: 3 - 2 = 1
```

각 주사위는 성공(`text-primary`) / 실패(`text-muted-foreground/30`)로 표시.

---

## 7. 전투 화면 상세 설계

### 7.1 적 영역 (Enemy Zone)

레퍼런스의 적 존 구조를 따릅니다.

```
┌─────────────────────────────────────────────────────────┐
│ [적 아바타 68x68]  [이름] [레벨] [BOSS/일반 뱃지]        │
│                    HP ████████░░░░ 65/127               │
│                    [상태이상 뱃지들]    ROUND 03 / 18 → │
└─────────────────────────────────────────────────────────┘
배경: bg-gradient-to-b from-red-950/25
```

### 7.2 전장 영역 (Battlefield)

```
[ENEMY 카드] ─── VS ─── [YOU 카드 or 빈 슬롯]   [타이머 27 SEC]
                                                  [배틀 로그]
```

- 적 카드: 항상 표시 (뒷면 → 결과 페이즈에서 공개)
- 내 카드: "Play a card" 플레이스홀더 → 클릭 시 손패에서 선택
- **거리(Distance) 표시**: 근거리/중거리/원거리를 아이콘으로 구분

### 7.3 내 플레이어 영역 (Player Zone)

```
[내 아바타 56x56]  [이름] HP ████████ 87/127
                          MOV 이동력 표시
                                        [페이즈 액션 버튼]
─────────────────────────────────────────────────────
손패 HAND — 5 CARDS
[카드1] [카드2] [카드3] [카드4] [카드5]
```

**페이즈별 버튼 변경**:
- MOVE 페이즈: `제출` / `휴식 (HP+1)` / `캐릭터 교체`
- ATTACK 페이즈: `공격 카드 제출` / `건너뛰기`
- DEFENSE 페이즈: `방어 카드 제출` / `포기`
- 결과 대기: `END TURN` 버튼 (비활성)

---

## 8. 덱 빌더 / 로비 화면 상세 설계

레퍼런스의 `DeckBuilder` 3열 레이아웃을 그대로 따릅니다.

### 8.1 좌측 사이드바 (220px / 모바일: 하단 탭)

```
[CARD ARENA 로고]
─────────────────
● Lobby        ← 홈/매칭 대기
● Deck         ← 덱 편성
● Collection   ← 카드 컬렉션
● Shop         ← 상점 (선택사항)
● Settings     ← 설정
─────────────────
[프로필 아바타]  Nickname
                W/L | WIN% | CARDS
```

### 8.2 중앙 카드 컬렉션 (flex-1)

```
[Card Collection]       [ALL] [이동] [공격] [방어] [특수]
──────────────────────────────────────────────────────────
[카드1] [카드2] [카드3]    ← 3열 그리드 (md: 2열, sm: 1열)
[카드4] [카드5] [카드6]
... (스크롤)
```

각 카드에 `IN DECK` 뱃지 표시 (덱에 편성된 경우).

### 8.3 우측 덱 패널 (280px)

```
[Active Deck]
──────────────
1. [카드 썸네일] 이름 | 타입 · 수치  [X]
2. [카드 썸네일] 이름 | 타입 · 수치  [X]
3. ...
5. Empty slot
──────────────
DECK COST  9 / 18
████████░░░░░░
──────────────
[SAVE DECK 버튼]
```

---

## 9. 로그인 / 회원가입 화면

```
┌──────────────────────────────────┐
│     CARD ARENA    [틸 글로우]     │
│                                  │
│  [이메일 입력]                   │
│  [비밀번호 입력]                  │
│                                  │
│  [LOGIN 버튼]                    │
│  회원가입 링크                   │
└──────────────────────────────────┘
배경: bg-background (#080c14)
```

API 연동: `POST /api/auth/login` / `POST /api/auth/signup`

---

## 10. 매칭 대기 화면

로비의 **Lobby 탭**에서 전환.

```
┌──────────────────────────────────────┐
│  덱 선택: [드롭다운]                 │
│  [RANKED MATCH 진입 버튼]            │
│                                      │
│  ◌ 매칭 대기 중...                   │
│  경과 시간: 00:34                    │
│  [취소]                              │
└──────────────────────────────────────┘
```

API: `POST /api/v1/match/queue` (지수 백오프 재시도 적용)  
WebSocket으로 매칭 완료 이벤트 수신 → `/battle/:matchId` 로 자동 이동.

---

## 11. 전투 결과 화면

```
┌──────────────────────────────────────┐
│     ████ VICTORY / DEFEAT ████       │
│                                      │
│  나 (87 HP 잔존)  vs  적 (0 HP)     │
│                                      │
│  총 라운드: 7 / 18                   │
│                                      │
│  [REPLAY 보기]  [로비로 돌아가기]    │
└──────────────────────────────────────┘
```

승리: `text-primary` 글로우 / 패배: `text-accent (red)` 글로우  
무승부: `text-yellow-400`

---

## 12. WebSocket 이벤트와 UI 연동

백엔드 WebSocket 이벤트에 따라 UI 상태를 업데이트합니다.

| 이벤트 | UI 처리 |
|---|---|
| `CARDS_DRAWN` | 손패 카드 추가 애니메이션 |
| `MOVE_SUBMITTED` | 거리 수치 업데이트, 선공 표시 |
| `DISTANCE_CHANGED` | 전장 거리 아이콘 전환 |
| `ATTACK_DECLARED` | 적 카드 공개 + 공격 주사위 표시 |
| `DEFENSE_SUBMITTED` | 방어 주사위 표시 |
| `DAMAGE_APPLIED` | StatBar HP 감소 애니메이션 |
| `TURN_END` | 페이즈 인디케이터 DRAW로 리셋 |
| `STATUS_EFFECT_APPLIED` | StatusBadge 추가 |
| `GAME_OVER` | 결과 화면 전환 |

---

## 13. 반응형 구현 체크리스트

- [ ] 모든 `grid-cols-*` 레이아웃에 `sm:`, `md:`, `lg:` 브레이크포인트 적용
- [ ] 카드 크기: 모바일 `w-[70px]`, 태블릿 `w-[88px]`, 데스크톱 `w-[108px]`
- [ ] 손패 영역: 모바일에서 `overflow-x-auto flex-nowrap` 가로 스크롤
- [ ] 사이드바: 모바일에서 `fixed bottom-0` 탭바로 전환
- [ ] 배틀 로그: 모바일에서 기본 숨김 + 토글 버튼
- [ ] 폰트 크기: 레퍼런스의 `text-[9px]`은 모바일에서 최소 `text-[10px]` 유지
- [ ] 버튼 터치 영역: 최소 44×44px (iOS 가이드라인)
- [ ] 타이머 카운트다운: 모바일에서도 항상 노출 (절대 위치 고정)
- [ ] 덱 빌더: 모바일에서 탭 UI로 컬렉션/덱 전환
- [ ] 전투 결과 화면: 모든 해상도에서 중앙 정렬

---

## 14. 스타일 컨벤션

레퍼런스 코드에서 사용된 패턴을 그대로 따릅니다.

```tsx
// ✅ font-display (Rajdhani) — 제목, 버튼 레이블
<span className="font-display font-bold tracking-widest">BATTLE</span>

// ✅ font-mono (JetBrains Mono) — 수치, 로그, 뱃지
<span className="font-mono text-[9px] tabular-nums">47/22</span>

// ✅ 게임 버튼 패턴
<button className="px-7 py-3 rounded border border-primary/50 bg-primary/10 text-primary
  font-display font-bold tracking-[0.15em] text-sm
  hover:bg-primary/18 hover:border-primary hover:shadow-[0_0_20px_rgba(0,201,167,0.22)]
  active:scale-[0.97] transition-all duration-150">
  END TURN
</button>

// ✅ 보더 스타일 — 레퍼런스의 미묘한 투명 보더
className="border border-border"  /* rgba(255,255,255,0.07) */

// ✅ 스크롤바 숨김 (공통 패턴)
className="[&::-webkit-scrollbar]:hidden"
```

---

## 15. 구현 우선순위

1. **P0 (필수)**: 디자인 토큰 설정 (`theme.css`, 폰트 로드)
2. **P0 (필수)**: 공통 레이아웃 (TopBar, 반응형 네비게이션)
3. **P0 (필수)**: 로그인 / 회원가입 화면
4. **P1 (핵심)**: 덱 빌더 화면 (3열 → 반응형)
5. **P1 (핵심)**: 전투 화면 기본 구조 (3행 → 반응형)
6. **P1 (핵심)**: ActionCard, StatBar, StatusBadge 컴포넌트
7. **P2 (중요)**: WebSocket 연동 및 실시간 상태 업데이트
8. **P2 (중요)**: PhaseIndicator, DiceResult 컴포넌트
9. **P3 (추가)**: 전투 결과 화면, 리플레이 뷰어
10. **P3 (추가)**: 애니메이션 (motion 라이브러리 활용)
