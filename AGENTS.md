# AI Coding Agent Guidelines for ft_transcendence

**프로젝트**: ft_transcendence (42 Common Core Final Project)  
**팀 규모**: 5명 (PO, PM, Tech Lead, 2× Developer)  
**최소 요구사항**: 14점 (현재: 15점)  
**최종 마감**: 프로젝트 제출 기한 내

---

## 1. 프로젝트 핵심 요구사항 (반드시 충족)

### 1.1 필수 구현 요소
- ✅ **웹 애플리케이션**: 프론트엔드(React) + 백엔드(NestJS) + 데이터베이스(PostgreSQL)
- ✅ **컨테이너화**: Docker & Docker Compose - **단일 명령어로 실행 가능**
- ✅ **Git 히스토리**: 모든 팀원의 커밋이 명확하게 표시되어야 함
- ✅ **Chrome 호환성**: 최신 안정 버전의 Google Chrome에서 작동
- ✅ **콘솔 에러 없음**: 브라우저 개발자 도구 콘솔에 경고/에러 없어야 함
- ✅ **Privacy Policy & Terms of Service**: 페이지 접근 가능 (바닥글 링크 등)
- ✅ **다중 사용자 지원**: 동시 접속 시 데이터 무결성 및 실시간 동기화 필수
- ✅ **HTTPS**: 백엔드에서 모든 통신은 HTTPS 필수

### 1.2 사용자 인증 (최소 요구)
- 이메일 & 비밀번호 기반 로그인
- 비밀번호 해싱 (bcrypt 등) 및 salting 필수
- 선택 사항: OAuth 2.0, 2FA (별도 모듈)

### 1.3 데이터베이스
- PostgreSQL + TypeORM (ORM)
- 명확한 스키마 및 테이블 관계 정의
- 마이그레이션 파일 버전 관리

---

## 2. 선택된 모듈 (15점 / 14점 최소)

| 카테고리 | 모듈명 | 타입 | 점수 | 상태 | 담당자 |
|---------|-------|------|------|------|--------|
| Web | Framework (React + NestJS) | Major | 2 | ⚠️ 검증 필요 | [login3] |
| Web | Real-time Features (WebSocket) | Major | 2 | ⚠️ 검증 필요 | [login3] |
| Web | User Interaction (Chat + Friends) | Major | 2 | ⚠️ 검증 필요 | [login4] |
| Web | ORM (TypeORM) | Minor | 1 | ⚠️ 검증 필요 | [login5] |
| Gaming | Web-based Game (Pong) | Major | 2 | ⚠️ 검증 필요 | [login4] |
| Gaming | Remote Players | Major | 2 | ⚠️ 검증 필요 | [login3] |
| AI | AI Opponent | Major | 2 | ⚠️ 검증 필요 | [login4] |
| DevOps | Monitoring System (Prometheus + Grafana) | Major | 2 | ⚠️ 검증 필요 | [login2] |
| **합계** | | | **15** | | |

### 모듈 검증 체크리스트
각 모듈은 다음 기준으로 검증되어야 함:
- ✅ 모든 요구사항이 **완전히** 구현되었는가?
- ✅ 평가 시연 시 각 기능이 **동작하는가?**
- ✅ README.md에서 **명확히 문서화**되었는가?
- ✅ 팀원 누구든지 그 모듈을 **설명할 수 있는가?**

---

## 3. 팀 역할 & 책임

### Product Owner (PO) - [login1]
**책임:**
- 기능 우선순위 결정 및 백로그 관리
- 각 모듈 완성 후 최종 검증
- 평가 대비 데모 시나리오 준비
- README.md 완성도 감독

**AI 에이전트 활용:**
- 모듈 요구사항 검증 체크리스트 생성
- 평가 기준 대비 기능 완성도 평가

---

### Project Manager (PM) - [login2]
**책임:**
- 스케줄 관리 및 마일스톤 추적
- DevOps 모니터링 시스템 구축 (Prometheus + Grafana)
- 팀 회의 조율 및 커뮤니케이션 채널 관리
- 위험 요소 및 병목 지점 파악

**AI 에이전트 활용:**
- Docker Compose 설정 및 배포 자동화
- Prometheus 메트릭 수집 및 Grafana 대시보드 설정
- 마일스톤별 작업 분배 문서 작성

---

### Technical Lead - [login3]
**책임:**
- 전체 시스템 아키텍처 설계
- 실시간 WebSocket 통신 로직 설계
- 원격 플레이어 동기화 메커니즘 구현
- 백엔드 API 스펙 정의

**AI 에이전트 활용:**
- NestJS 아키텍처 패턴 및 모듈 구조 제안
- Socket.io 이벤트 핸들러 템플릿 생성
- 동시성 제어 및 레이턴시 최적화 로직 검토

---

### Developer (Frontend) - [login4]
**책임:**
- React UI/UX 구현
- 게임 물리 엔진 및 렌더링
- AI 대전 로직 구현
- 실시간 상태 동기화 UI

**AI 에이전트 활용:**
- React 컴포넌트 구조 및 상태 관리 (Redux/Context)
- Canvas 또는 WebGL 기반 게임 렌더링 코드
- AI 패들 이동 알고리즘 생성

---

### Developer (Backend) - [login5]
**책임:**
- PostgreSQL 데이터베이스 스키마 설계
- TypeORM 엔티티 및 마이그레이션
- REST API 엔드포인트 구현
- 인증/인가 로직

**AI 에이전트 활용:**
- TypeORM 리포지토리 패턴 및 쿼리 생성
- 데이터베이스 마이그레이션 스크립트 작성
- API 문서 및 Swagger 정의

---

## 4. 개발 환경 및 시작 절차

### 프로젝트 구조
```
/home/kyou/trans/
├── README.md                      # 최종 평가 문서
├── AI_USAGE.md                    # AI 사용 내역 기록
├── .env.example                   # 환경 변수 예시
├── docker-compose.yml             # Docker 구성
├── transcendence_backend/         # NestJS 애플리케이션
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── transcendence_frontend/        # React 애플리케이션
│   ├── src/
│   ├── Dockerfile
│   └── package.json
└── Documents/                     # 팀 문서 (회의록, 설계)
```

### 실행 명령어
```bash
# 초기 설정
cp .env.example .env

# 단일 명령어로 전체 애플리케이션 시작
docker-compose up --build

# 애플리케이션 접속
https://localhost
```

### 개발 모드 (로컬)
```bash
# 백엔드 (NestJS)
cd transcendence_backend
npm install
npm run start:dev

# 프론트엔드 (React) - 별도 터미널
cd transcendence_frontend
npm install
npm run dev
```

---

## 5. 코드 검토 및 품질 기준

### Git 커밋 메시지 컨벤션
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type:**
- `feat`: 새 기능 (모듈, 엔드포인트 추가)
- `fix`: 버그 수정
- `refactor`: 코드 구조 개선
- `docs`: 문서 추가/수정
- `test`: 테스트 추가
- `chore`: 빌드, 의존성 업데이트

**예시:**
```
feat(websocket): implement real-time game synchronization

- Add Socket.io event handlers for player movements
- Implement latency compensation algorithm
- Add connection/disconnection handling

Closes #42
```

### 코드 리뷰 체크리스트
**모든 PR은 최소 1명의 팀원 승인 필수**

- ✅ 코드가 프로젝트 컨벤션을 따르는가?
- ✅ 함수/클래스에 주석이 있는가?
- ✅ 에러 처리가 적절한가?
- ✅ 데이터베이스 쿼리 성능은 적절한가?
- ✅ 보안 취약점은 없는가?
  - SQL Injection 방지 (ORM 사용)
  - CSRF 토큰 검증
  - 비밀번호 해싱
  - HTTPS 사용
- ✅ 테스트 커버리지는 충분한가?

---

## 6. 평가 기준 및 검증 프로세스

### 평가 시점에서 확인 사항

#### A. 기능 검증 (Function-First)
1. **계정 시스템**
   - 가입 → 로그인 → 프로필 수정 정상 작동
   - 비밀번호 해싱 확인 (DB에 평문 저장 금지)

2. **게임 플레이**
   - 2명이 동시 접속 후 실시간 게임 진행
   - 원격 플레이어 간 지연 시간 < 200ms
   - 네트워크 끊김 후 재연결 가능

3. **AI 대전**
   - AI 패들이 공을 반격하는가?
   - 난이도가 합리적인가?
   - 게임 종료 및 점수 기록이 정상인가?

4. **실시간 기능**
   - 채팅 메시지 전송 < 1초
   - 친구 온라인 상태 실시간 업데이트
   - 동시 사용자 > 5명일 때 성능 저하 없음

5. **DevOps 모니터링**
   - Grafana 대시보드 접근 가능
   - CPU, 메모리, 네트워크 메트릭 표시
   - 알림 규칙 설정 및 작동

#### B. 기술 구현 검증
- Docker 단일 명령어 실행 성공
- 모든 팀원의 git 커밋 히스토리 확인
- Privacy Policy & Terms of Service 페이지 존재
- 콘솔 에러/경고 없음

#### C. 문서 검증
- README.md 완성도 (팀 정보, 기술 스택, 모듈 리스트, 실행 방법)
- 각 모듈별 구현 설명 및 담당자 명시
- AI 사용 범위 투명하게 기록 (AI_USAGE.md)

---

## 7. AI 에이전트 활용 가이드

### 에이전트가 도울 수 있는 작업
✅ **DO**: 다음 작업에서 AI를 활용
- 프레임워크 설정 및 보일러플레이트 생성
- API 엔드포인트 스켈레톤 작성
- 반복적인 CRUD 구현
- 테스트 케이스 작성
- 문서 작성 및 주석 생성
- 버그 디버깅 및 성능 최적화 아이디어

❌ **DON'T**: 이 작업은 팀이 직접 수행
- 아키텍처 및 설계 결정 (Tech Lead)
- 모듈 요구사항 정의 (PO)
- 핵심 게임 로직 (이해하고 구현)
- 보안 관련 결정 (암호화, 토큰 전략)

### 코드 검증 프로세스
1. AI가 생성한 코드는 **반드시 팀원이 검토**
2. 공식 문서(NestJS, React, Socket.io) 대비 정확성 확인
3. 실제 동작 테스트 후 병합
4. AI_USAGE.md에 기록 (어떤 부분에 AI를 사용했는지)

---

## 8. 마일스톤 및 일정

### Phase 1: 프로젝트 설정 (Week 1-2)
- [ ] GitHub 저장소 초기화 및 팀원 접근 권한 설정
- [ ] Docker 및 Docker Compose 구성
- [ ] 프론트엔드 & 백엔드 프로젝트 초기화
- [ ] 데이터베이스 스키마 초안 작성

### Phase 2: 핵심 기능 구현 (Week 3-4)
- [ ] 사용자 인증 시스템 (회가입, 로그인, 프로필)
- [ ] WebSocket 기반 실시간 통신 인프라
- [ ] 기본 Pong 게임 구현
- [ ] 채팅 & 친구 시스템

### Phase 3: 고급 기능 (Week 5-6)
- [ ] AI 대전 로직
- [ ] 원격 플레이어 게임 동기화
- [ ] DevOps 모니터링 시스템 (Prometheus + Grafana)

### Phase 4: 최적화 & 평가 준비 (Week 7-8)
- [ ] 성능 최적화 (지연 시간, 메모리)
- [ ] 보안 감시 및 수정
- [ ] README.md 및 문서 최종화
- [ ] AI_USAGE.md 기록 완료
- [ ] 평가 데모 시나리오 준비

---

## 9. 연락처 & 에스컬레이션

**기술적 이슈:**
- Tech Lead: [login3] - 아키텍처 결정
- Backend Lead: [login5] - DB & API 문제
- Frontend Lead: [login4] - UI/UX & 게임 로직

**프로젝트 관리:**
- PM: [login2] - 일정, 위험, 커뮤니케이션
- PO: [login1] - 기능 우선순위, 평가 준비

---

## 10. 평가 후 점수 배분

**기본 점수: 14점 이상 필수**

| 항목 | 기준 | 점수 |
|------|------|------|
| 필수 기능 | 모두 작동 | Pass/Fail |
| 모듈 구현 | 14점 이상 | 14-15점 |
| 보너스 모듈 | 추가 모듈 | +1~5점 |
| 코드 품질 | 구조, 성능, 보안 | 최종 점수 ±5% |

---



# 계획

다음 조건 중 하나라도 해당하면 구현 전에 짧은 1페이지 계획을 남긴다.
    작업 범위가 넓다.
    요구사항이 애매하다.
    
포함할 항목:

    배경
    문제
    목표
    비목표
    제약
    구현 개요
    검증 계획
    되돌리기 또는 복구 메모
작고 명확한 수정은 주변 코드를 읽은 뒤 바로 진행해도 된다.


# 코드 품질
    수정 전 관련 코드와 테스트를 먼저 읽는다.
    숨은 마법보다 의도가 드러나는 코드를 선호한다.
    플랫폼 의존 로직은 얇은 경계 모듈 뒤로 숨기고, 앱 코드는 명확한 API만 호출하게 유지한다.
    실제 중복이 생기기 전에는 과도한 추상화를 만들지 않는다.
    함수나 파일이 길어져 동작 파악이 어려워지면 분리한다.
    경로, 인코딩, 시간, 프로세스 실행, 브라우저/컨테이너 차이를 항상 의식한다.
    구조화된 API를 우선하고, ad hoc 문자열 결합으로 JSON, 셸 인수, 경로를 만들지 않는다.

권장 기준:

    파일 300 LOC 안팎
    함수 50 LOC 안팎
    매개변수 5개 이하
    복잡도 10 이하

기준을 넘겨야 한다면 이유를 계획 문서나 작업 설명에 남긴다.

# Git / PR

    커밋은 작고 되돌리기 쉽게 유지한다.
    현재 작업과 관련된 파일만 stage 한다.
    명시적 요청 없이 히스토리 재작성, 태그 이동, force-push를 하지 않는다.
    PR에는 사용자 영향, 데이터 포맷 변화, 운영 영향, 검증 내용을 포함한다.


**마지막 업데이트**: 2026-04-30  
**문서 작성**: AI Coding Agent Guidelines  
**참고**: ft_transcendence 공식 과제 문서 v20.0
