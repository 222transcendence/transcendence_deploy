# AI #167/#168 경계 정리 계획

## 배경

Deploy `dev`에는 Backend PR #176과 Frontend AI 변경이 이미 통합되어 있다. 현재
Backend 작업트리는 `origin/dev`의 detached HEAD에서 167·168 관련 보완 변경을
가지고 있고, 루트는 서브모듈 포인터가 수정된 상태다.

## 문제

- 미커밋 변경이 어느 기능 브랜치에 속하는지 경계가 없다.
- #167은 estimator/report는 있으나 population default를 runtime에 자동 반영하지 않는다.
- #168은 WPM·accuracy·reaction, typo·abandon 일부만 관측하며 correction,
  word-length, type preference는 아직 미구현이다.
- 오래된 Deploy PR을 다시 머지하면 서브모듈 포인터가 되돌아갈 수 있다.

## 목표

현재 변경을 잃지 않고 Backend 작업 브랜치에 고정한다. 루트 서브모듈 포인터와
Frontend 포인터를 별도로 검증한 뒤, #167·#168의 실제 데이터 수집/완료 조건을
구현 범위와 후속 작업으로 명확히 나눈다.

## 비목표

- 기존 변경 삭제, reset, force-push
- 닫힌 Deploy PR #92 재오픈 또는 재머지
- 데이터가 없는 상태에서 임의의 population default 확정
- 이번 정리 단계에서 correction/word-length/type preference 로직을 즉시 구현

## 제약

- 서브모듈은 독립 Git 저장소다.
- Backend는 현재 detached HEAD이며 미커밋 변경을 보존해야 한다.
- 원시 입력·개인정보·인증정보는 수집하거나 저장하지 않는다.
- AI practice와 PvP 데이터 출처를 분리해 추적한다.

## 구현 개요

1. Backend 현재 커밋을 기준으로 보존용 작업 브랜치를 만든다.
2. 미커밋 변경은 그대로 유지하고 테스트/차이를 기록한다.
3. 수집 데이터 계약을 `ParticipantPerformance`와 `WordAttemptRecord` 기준으로
   점검한다.
4. #167은 동의된 인간 표본, 유효 경기, 플레이어별 cap, 재현 가능한 report를
   기준으로 평가한다.
5. #168은 지표별 관측 가능 여부를 분리하고 미관측 값은 null/default로 유지한다.
6. Backend 커밋 후에만 루트 서브모듈 포인터를 갱신한다.

## 검증 계획

- 루트/각 서브모듈 `git status`, branch, diff 보존 확인
- 관련 단위 테스트와 Backend build 실행
- 중복·AI 참가자·비정상 경기·동의 없는 표본 제외 테스트
- 표본 수와 산출 profile/version이 report에 재현 가능하게 기록되는지 확인
- 동일한 입력과 버전에서 동일한 결과가 나오는지 확인

## 되돌리기/복구

작업 브랜치와 현재 파일 변경을 유지한다. 포인터 갱신 전에는 루트 커밋을 만들지
않으며, 문제가 생기면 루트 포인터만 기존 커밋으로 되돌리고 Backend 브랜치의
변경은 별도로 보존한다. `reset --hard`, 강제 push, 서브모듈 파일 삭제는 하지 않는다.
