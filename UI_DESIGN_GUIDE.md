# Frontend UI Design Guide — Transcendence (산성비 Acid Rain)

이 문서는 기존 TCG(카드 듀얼) 기준으로 작성된 Tailwind + shadcn/ui + Radix 스택 가이드를 대체한다.
그 가이드는 실제로 `transcendence_frontend`에 도입된 적이 없는 아스피레이셔널 문서였다 —
실제 스택은 지금도 **플레인 CSS + `:root` 커스텀 프로퍼티**(`src/index.css`)이며, 게임을 산성비로
교체하는 이번 전면 리디자인에서도 이 방식을 그대로 진화시킨다.

## 0. 왜 Tailwind/shadcn을 새로 들이지 않는가

- 팀 규모 4~5인, 학교 프로젝트 마감이 있는 상태에서 빌드 도구 추가 + 기존 페이지 전체 마크업 재작성은
  일정 대비 리스크가 크다.
- 현재 `src/index.css`에 이미 다크 테마 토큰 체계(`--bg-primary`, `--accent-cyan` 등)가 잡혀 있어,
  팔레트만 갈아끼우고 흩어진 클래스명을 정리하는 쪽이 훨씬 저렴하다.
- 컴포넌트 라이브러리(shadcn 등)·Storybook 같은 인프라는 도입하지 않는다 — 마감 있는 프로젝트에 과함.

## 1. 기술 스택 (변경 없음)

React 18 + Vite + TypeScript, React Router. 스타일링은 **plain CSS** — `src/index.css`(전역 토큰 +
공통 클래스) + `src/App.css`. CSS Modules, styled-components, Tailwind 전부 도입하지 않는다.

## 2. 디자인 토큰

기존 `:root`(`src/index.css`)의 TCG용 팔레트(`--accent-cyan`, `--accent-purple`, `--accent-neon`)를
산성비 컨셉("산성비가 내리는 밤" — 형광 라임/그린 계열 산성비 + 경고색 대비)으로 교체한다.

```css
:root {
  --font-sans: 'Outfit', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --bg-primary: #0a0c16;
  --bg-secondary: #121528;

  --accent-acid: #b6ff3c;     /* 산성비 그린 — 단어/강조 */
  --accent-warning: #ffcc33;  /* 임박 경고(단어 낙하 임박) */
  --accent-danger: #ff4d6d;   /* 상대 공격/데미지 */

  --text-primary: #ffffff;
  --text-secondary: #a0aec0;
  --text-muted: #718096;

  --glass-bg: rgba(255, 255, 255, 0.03);
  --glass-border: rgba(255, 255, 255, 0.06);
  --glass-glow: rgba(182, 255, 60, 0.15);

  --error: #ff4d4d;
  --error-bg: rgba(255, 77, 77, 0.1);
  --success: #00e676;

  --shadow-lg: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
  --transition-smooth: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
```

역할표:

| 역할 | 색상 | 사용처 |
|---|---|---|
| Acid(그린) | `--accent-acid` | 내 플레이어 HP, 정타 이펙트, 강조 버튼 |
| Warning(옐로) | `--accent-warning` | 바닥에 가까워진 단어, 남은 시간 경고 |
| Danger(레드) | `--accent-danger` | 상대 HP 감소, 미스(splash damage) 이펙트 |
| 배경 | `--bg-primary` / `--bg-secondary` | 전체 배경 / 패널 배경 |
| Glass | `--glass-bg` / `--glass-border` | 카드·모달의 유리질감 패널(기존 패턴 유지) |

폰트는 기존 `Outfit` 유지(제목·본문 공용) — 별도 display/mono 폰트 추가 도입 안 함.

## 3. 재사용 프리미티브 (최소 범위)

기존 1372줄 `index.css`에 흩어진 임의 클래스명(`.dashboard-container`, `.stat-card`, `.badge-status`
등)을 아래 6개 프리미티브로 수렴시킨다. 새 클래스를 만들 때도 이 네이밍을 따른다.

| 프리미티브 | 클래스 접두사 | 용도 |
|---|---|---|
| Button | `.btn`, `.btn-primary`, `.btn-ghost` | 모든 액션 버튼 (사이즈 변형: `.btn-sm`/`.btn-lg`) |
| Card | `.card` | 패널/컨테이너 (glass 배경 + 보더, 기존 `.auth-container` 패턴 일반화) |
| Input | `.input` | 텍스트 입력 — 로그인, 단어 입력창 공용 |
| Modal | `.modal-overlay` / `.modal` | 매치 종료, 확인 다이얼로그 |
| Badge | `.badge`, `.badge-status` | 상태 표시(온라인/대기중/게임중 등) |
| HP Bar | `.hp-bar`, `.hp-bar-fill` | 산성비 대전 체력바 (기존 TCG `StatBar` 대체) |

각 프리미티브는 variant를 modifier 클래스로 표현한다(`.btn-primary`, `.btn-ghost` 등). 컴포넌트별
전용 클래스가 필요하면 `{page}-{element}` 네이밍(`lobby-room-card`, `waiting-ready-toggle` 등 기존
컨벤션)을 그대로 따른다.

## 4. 반응형

기존과 동일하게 모바일 우선은 아니지만, 모든 화면은 최소한 아래 3구간에서 깨지지 않아야 한다(과제
`III.3` "모든 기기에서 접근 가능한 반응형 프론트엔드" 요건).

| 구간 | 기준 |
|---|---|
| 모바일 | `< 640px` |
| 태블릿 | `640px ~ 1024px` |
| 데스크톱 | `>= 1024px` |

미디어 쿼리는 플레인 CSS `@media (min-width: ...)`로 처리, 별도 브레이크포인트 시스템(Tailwind 설정)
도입하지 않는다.

## 5. 페이지별 적용 범위

기존 페이지 인벤토리(`src/pages/`)를 그대로 유지하되 토큰/프리미티브 교체 대상:

- `LoginPage` / `SignupPage` / `OAuthCallbackPage` — Card + Input + Button 프리미티브로 정리.
- `HomePage`, `ProfilePage`, `StatsPage`, `LeaderboardPage` — Card + Badge 위주, 로직 변경 없음.
- `LobbyPage` / `WaitingRoomPage` — Card(RoomCard) + Badge(상태), 캐릭터 선택 UI(`CharacterSelectModal`)
  는 캐릭터 개념 제거에 따라 삭제.
- `GameBoardPage`(신규 산성비 화면) — 낙하하는 단어(DOM 또는 Canvas), 입력창(Input), 양쪽 HP Bar,
  매치 종료 Modal. TCG 전용 컴포넌트(`PhaseBanner`, `HandArea`, `CardItem`, `DiceRollAnimation`,
  `SkillEffectOverlay`)는 전부 삭제하고 이 화면 전용 컴포넌트를 새로 만든다.
- `PrivacyPolicyPage` / `TermsOfServicePage` — 스타일 변경 최소, 콘텐츠는 그대로.

## 6. WebSocket 이벤트 ↔ UI 연동

산성비 게임 화면(`GameBoardPage`)이 구독할 이벤트와 그에 따른 UI 반응. 이벤트 페이로드 상세는
`architecture_design/WEBSOCKET_PROTOCOL.md` §6.3이 정본.

| 이벤트 | UI 처리 |
|---|---|
| `match_ready` | 카운트다운 오버레이 표시 |
| `match_start` | 카운트다운 종료, 단어 스폰 시작 |
| `word_spawn` | 새 단어를 낙하 애니메이션으로 추가 |
| `word_cleared` | 해당 단어 제거 + 정타 이펙트(`--accent-acid` 플래시) + 상대 HP Bar 감소 |
| `word_missed` | 해당 단어 제거 + 미스 이펙트(`--accent-danger` 플래시) + 양쪽 HP Bar 감소 |
| `submit_rejected` | 입력창에 짧은 실패 피드백(레이스 패배/오타) |
| `opponent_disconnected` | 상단 배너 "상대가 연결이 끊겼습니다 (n초 후 몰수패)" |
| `opponent_reconnected` | 배너 해제 |
| `match_end` | 결과 Modal 표시(승/패/무, 재대결·로비 복귀 버튼) |

## 7. 구현 우선순위

1. **P0**: `:root` 토큰 교체(§2), 6개 프리미티브 클래스 정리(§3)
2. **P0**: 로그인/회원가입 화면 프리미티브 적용
3. **P1**: 산성비 게임 화면(단어 낙하, 입력, HP Bar, 결과 Modal)
4. **P1**: 로비/대기방 화면(캐릭터 선택 제거 반영)
5. **P2**: 프로필/통계/리더보드 화면 톤 통일
6. **P2**: 반응형 점검(§4 3구간)
7. **P3**: 자잘한 인터랙션 다듬기(애니메이션, 트랜지션)
