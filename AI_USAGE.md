# AI Usage Report

이 문서는 `ft_transcendence` 프로젝트 진행 중 AI 도구를 사용한 범위, 검토 방식, 산출물을 평가자가 확인할 수 있도록 기록한다.

## 1. Usage Policy
- AI는 반복적인 보일러플레이트, 문서 초안, 테스트 아이디어, 디버깅 가설 정리에만 사용한다.
- 아키텍처 결정, 모듈 요구사항 확정, 게임 밸런스, 보안 정책은 팀원이 검토하고 직접 결정한다.
- AI가 제안한 코드는 팀원이 파일 단위로 읽고, 공식 문서와 로컬 테스트 결과로 검증한 뒤 반영한다.
- AI 사용 내역이 포함된 PR은 일반 코드와 동일하게 최소 1명 이상의 팀원 리뷰를 거친다.

## 2. Tools Used
| Tool | Main Purpose | Output Type |
| :--- | :--- | :--- |
| Claude (Anthropic) / Claude Code | 아키텍처 문서 작성·정리, 백엔드/프론트엔드 코드 작성 보조, 디버깅 가설 정리, 설계 명세 검토 | 코드 패치, 문서 초안, 설계 검토 의견, 체크리스트 |
| ChatGPT / Codex | 코드베이스 탐색, 문서 정리, 테스트·검증 절차 제안 | 코드 패치, 문서 초안, 체크리스트 |
| GitHub Copilot | 반복적인 TypeScript/NestJS/React 코드 작성 보조 | 함수·컴포넌트 초안 |
| Official documentation with search | 프레임워크/API 사용법 확인 | 근거 확인 및 구현 보정 |

## 3. Usage Log
| Area | Prompt / Request Summary | AI-assisted Result | Human Verification |
| :--- | :--- | :--- | :--- |
| Framework setup | React, NestJS, TypeORM, Docker Compose 기본 구조와 실행 흐름 정리 | 프로젝트 구조, 실행 문서, 설정 점검 체크리스트 작성 보조 | 팀원이 Docker 빌드와 서비스 health check로 확인 |
| Authentication | 이메일/비밀번호 인증, bcrypt 해싱, JWT guard 테스트 관점 정리 | 인증 API 구현·테스트 케이스 설계 보조 | DB에 평문 비밀번호가 저장되지 않는지 확인 |
| Real-time lobby/chat | WebSocket 이벤트, reconnect, 에러 처리 흐름 검토 | 로비/채팅 이벤트 계약과 예외 처리 방향 정리 | 브라우저와 백엔드 로그로 송수신 확인 |
| Acid Rain game | 서버 권위 단어 스폰, 입력 판정, HP 변경, 종료 조건 문서화 | 산성비 게임 명세와 WebSocket 프로토콜 문서 정리 보조 | 팀원이 `GAME_DESIGN.md`, `WEBSOCKET_PROTOCOL.md` 기준으로 검토 |
| AI opponent | 반응 지연, 타속, 실수율 기반 자동 단어 입력 방식 아이디어 정리 | 완벽하지 않은 사람다운 AI 대전 로직 초안 | 게임 밸런스와 난이도 수치는 팀원이 조정 |
| Database / ORM | TypeORM 엔티티, 마이그레이션, MatchHistory JSONB 구조 점검 | 스키마 문서와 마이그레이션 검토 포인트 정리 | 마이그레이션 실행 및 API 응답으로 검증 |
| Monitoring | Prometheus/Grafana 구성과 주요 메트릭 후보 정리 | 모니터링 대시보드 구성 항목과 검증 절차 보조 | 컨테이너 상태와 Prometheus query UI로 확인, Grafana 대시보드는 DevOps 모듈 검증 대상 |
| Architecture docs | `architecture_design/*.md` 전 영역 — 게임 명세, DB 모델, API, WebSocket 프로토콜, AI 상대 명세 작성 및 실제 구현 기준으로 갱신 | Claude(Anthropic)로 문서 초안 생성 및 코드 기반 내용 정정 | 각 담당 팀원이 실제 코드와 대조하여 검토·머지 승인 후 반영 |
| Documentation | README, AI_USAGE, 설계 문서 잔여 용어 점검 | 평가용 실행 가이드와 AI 사용 감사 로그 갱신 | PR 리뷰에서 팀원이 문서 정확성 확인 |

## 4. AI-assisted Artifacts
| Artifact | Files / Scope | Notes |
| :--- | :--- | :--- |
| Project runbook | `README.md`, `.env.example`, Docker-related notes | 처음 보는 평가자가 실행 가능한 절차 중심으로 정리 |
| Architecture documents | `architecture_design/*.md` | 산성비 게임, DB, API, WebSocket 계약 문서 보강 |
| Backend implementation support | `transcendence_backend/src/**` | NestJS 서비스, 컨트롤러, 게이트웨이, TypeORM 마이그레이션 작성 보조 |
| Frontend implementation support | `transcendence_frontend/src/**` | React 화면, 소켓 훅, 게임 UI 상태 처리 작성 보조 |
| Test and verification notes | `CHECKLIST.md`, PR descriptions | 평가 전 확인할 수 있는 기능·검증 증빙 정리 |

## 5. Review Checklist
AI 보조 산출물을 merge하기 전 팀원이 확인할 항목이다.

- 코드가 현재 설계 문서와 실제 API/WebSocket 계약을 따르는가?
- AI가 만든 가정이 코드 주석이나 문서에 남아 있지 않은가?
- 보안 관련 로직은 공식 문서와 로컬 테스트로 확인했는가?
- 게임 규칙과 밸런스 수치는 PO/Tech Lead 결정과 일치하는가?
- 브라우저 콘솔, 백엔드 로그, 테스트 결과에 경고/에러가 없는가?

## 6. Conclusion
본 프로젝트의 핵심 요구사항, 아키텍처, 게임 규칙, 보안 정책은 팀 논의와 코드 리뷰를 통해 결정했다. AI는 생산성 보조 도구로 사용했으며, 최종 책임과 검증은 팀원이 수행한다.
