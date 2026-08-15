# ft_transcendence PM Master Checklist

이 문서는 PM이 전체 스케줄을 관리하고, 체크리스트와 커밋 내역을 1:1로 대응시켜 과제 완성도를 증빙하기 위한 기준 문서입니다.

## 사용 규칙
- 각 항목은 고유 ID(P1-01, P2-03 등)로 관리합니다.
- 각 항목은 아래 3가지가 모두 있어야 Done 처리합니다.
1. 구현 증빙 (코드/설정/문서)
2. 검증 증빙 (실행/테스트/데모 결과)
3. 커밋 증빙 (ID가 포함된 커밋)
- 커밋 메시지 권장 형식:
  - feat(scope): summary [P2-01]
  - fix(scope): summary [P3-02]
  - docs(scope): summary [P4-01]

---

## Phase 1. Foundation and Environment (Week 1-2)

| ID | Task | Owner | Status | Implementation Evidence | Validation Evidence | Commit(s) |
|---|---|---|---|---|---|---|
| P1-01 | Repository and team access setup | hijae | Done | .gitmodules, README.md | git submodule status & gh api checks | feat(infra): repository setup & branch strategy [P1-01] |
| P1-02 | .env.example -> .env bootstrapping flow documented | hijae | Done | .env.example, README.md | cp .env.example .env validation | feat(infra): initial docker-compose configuration [P1-02] |
| P1-03 | docker-compose up --build works from clean state | hijae | Done | docker-compose.yml | docker-compose up --build output | feat(infra): initial docker-compose configuration [P1-02] |
| P1-04 | HTTPS endpoint reachable at https://localhost | hijae | Done | nginx/nginx.conf, nginx/entrypoint.sh | curl -k -I https://localhost check | feat(infra): initial docker-compose configuration [P1-02] |
| P1-05 | Base frontend/backend service health checks verified | hijae | Done | health.controller.ts | curl -k /api/health check | feat(infra): initial docker-compose configuration [P1-02] |
| P1-06 | README runbook updated for first-time setup | hijae | Done | README.md | README instructions validation | feat(infra): initial docker-compose configuration [P1-02] |

---

## Phase 2. Core Product Features (Week 3-4)

| ID | Task | Owner | Status | Implementation Evidence | Validation Evidence | Commit(s) |
|---|---|---|---|---|---|---|
| P2-01 | Authentication: signup/login/profile update E2E | jishin | Done | auth/auth.controller.ts, auth.service.ts, strategies/ft.strategy.ts | auth.service.spec.ts, ft.strategy.spec.ts, ft-auth.guard.spec.ts + OAuth 흐름 리허설(2026-08-15) | feat(auth): implement 42 OAuth 2.0 login with FtStrategy [#10] |
| P2-02 | Password hashing and salting verification in DB | hijae | Done | auth.service.ts | test_auth.sh E2E signup test | feat(auth): implement signup api with password hashing [#7] [P2-02] |
| P2-03 | Basic Acid Rain typing battle gameplay loop complete | yuhyoon | Done | GAME_DESIGN.md, WEBSOCKET_PROTOCOL.md | 산성비 게임 흐름 문서 검토 | backend#72, backend#75, deploy#65 |
| P2-04 | WebSocket real-time sync for game state | jishin | Done | game/acid-rain/acid-rain.gateway.ts | acid-rain.gateway.spec.ts | feat(game): AcidRainGateway — join/leave/word_submit 핸들러 구현 [#74] |
| P2-05 | Chat messaging latency target (<1s) validated | jishin | Done | chat/chat.gateway.ts, chat.service.ts | chat.gateway.spec.ts, chat.service.spec.ts + 5인 동시 접속(관전 1명 포함) 상황에서 체감상 즉시 도착 직접 확인(2026-08-15, yuhyoon) | feat(chat): implement chat system with Socket.io and DB persistence [#28] |
| P2-06 | Friend system flow: add/accept/status update | kyouhele | Done | friend/friend.service.ts, friend.controller.ts, entities/friend.entity.ts | friend.service.spec.ts | feat(#13): implement friend API module service and controller |

---

## Phase 3. Advanced Modules (Week 5-6)

| ID | Task | Owner | Status | Implementation Evidence | Validation Evidence | Commit(s) |
|---|---|---|---|---|---|---|
| P3-01 | Remote players match flow stable under reconnect | hisong | Done | game/acid-rain/acid-rain.service.ts (handleDisconnect/handleReconnect) | acid-rain.service.spec.ts, acid-rain.gateway.spec.ts + 재접속 로직 리허설(2026-08-15) | fix(game): 연결 끊김 시 30초 후 강제 탈락/승리 처리하던 로직 제거 (#161) |
| P3-02 | AI opponent card strategy logic complete | kyouhele | Done | game/acid-rain/ai/ai-executor.ts, ai-scheduler.ts, state-evaluator.ts | ai-executor.spec.ts, ai-scheduler.spec.ts, ai-balance.smoke.spec.ts | feat(ai): add human-like executor and scheduler |
| P3-03 | Match result persistence and score history integrity | yuhyoon | Done | game.service.ts (recordMatchHistory) | game-engine.spec.ts game-over tests | feat(game): implement game over logic, match persistence, and redis teardown [P3-03] |
| P3-04 | Prometheus metrics exposed and scraped | hisong | Done | prometheus/prometheus.yml, metrics/metrics.registry.ts, metrics.controller.ts | docker-compose prometheus 서비스가 backend:3000/metrics, node-exporter:9100 스크레이핑 확인 | feat(metrics): add prom-client registry, http duration interceptor, /metrics endpoint [#12] [P7-01] |
| P3-05 | Grafana dashboard with CPU/memory/network panels | hisong | Done | grafana/provisioning/dashboards/json/transcendence-overview.json | 호스팅된 Grafana 대시보드 직접 접속 확인(2026-08-15) | feat(monitoring): Grafana 대시보드 추가 [#13] |
| P3-06 | Monitoring alert rule smoke test complete | hisong | Done | grafana/provisioning/alerting/rules.yml, contactpoints.yml, policies.yml | Grafana Alerting > Alert rules에서 4개 규칙(API 에러율/응답시간/WebSocket 급감/메모리) 전부 Normal 상태로 정상 평가 중 직접 확인(2026-08-15, yuhyoon) | feat(grafana): Grafana 알림 규칙 4종 + 웹훅 채널 provisioning (#14) |

---

## Phase 4. Hardening and Evaluation Readiness (Week 7-8)

| ID | Task | Owner | Status | Implementation Evidence | Validation Evidence | Commit(s) |
|---|---|---|---|---|---|---|
| P4-01 | Browser console warning/error zero baseline | yuhyoon | Done | (프론트 전체) | 호스팅된 사이트에서 Chrome DevTools 콘솔 직접 확인(2026-08-15, yuhyoon) |  |
| P4-02 | Privacy Policy and Terms of Service page reachable | jishin | Done | frontend/src/pages/PrivacyPolicyPage.tsx, TermsOfServicePage.tsx, components/Footer.tsx | 호스팅된 사이트에서 Footer 링크로 두 페이지 직접 접속 확인(2026-08-15, yuhyoon) | feat(legal): add PrivacyPolicy and TermsOfService pages with Footer component [#11] |
| P4-03 | Multi-user concurrency check (>5 users) completed | yuhyoon | Done | game/acid-rain/acid-rain.service.ts (AcidRainSession.participants[], 2~4인 배틀로얄 + 다중 방 동시 운영) | 5인 이상 동시 접속 정상 동작 직접 확인(2026-08-15, yuhyoon) |  |
| P4-04 | README module-to-owner and demo flow finalized | yuhyoon | In Progress | README.md (팀원 개별 기여, 기술스택 선택 이유, 모듈 선택 이유/담당자, 프로젝트 관리 방식 섹션 보강, 2026-08-15) | PDF 평가표 8개 필수 섹션 대조 완료 | (커밋 대기) |
| P4-05 | AI_USAGE transparency and review log finalized | yuhyoon | Done | AI_USAGE.md (정책/도구/영역별 사용 로그/산출물/리뷰 체크리스트/결론 전부 기재) | 내용 완전성 직접 검토 완료(2026-08-15) | docs: update README.md and AI_USAGE.md with final module list |
| P4-06 | Final demo script and fallback scenario rehearsed | yuhyoon | In Progress | (문서 없음) | 평가표(PDF) 기준 섹션별 구두 리허설 진행 중(2026-08-15, PO 개인 기여/모듈 13개 중 12개/재접속/OAuth/모니터링 완료) |  |

---

## Milestone Summary

| Phase | Done | In Progress | Blocked | TODO |
|---|---:|---:|---:|---:|
| Phase 1 | 6 | 0 | 0 | 0 |
| Phase 2 | 6 | 0 | 0 | 0 |
| Phase 3 | 6 | 0 | 0 | 0 |
| Phase 4 | 4 | 2 | 0 | 0 |

## PM Weekly Review Log

| Date | Reviewer | Phase Reviewed | Missing IDs | Missing Commit Evidence | Top Risk | Next 3 Commits |
|---|---|---|---|---|---|---|
| 2026-08-15 | yuhyoon (PO) | Phase 2-4 전체 | P4-03, P4-05 | P4-04(README 갱신 미커밋) | P4-03(5인 이상 동시접속 테스트 미실시), P2-05/P3-06(검증 증빙 부족) | 1) README 갱신 커밋 [P4-04] 2) AI_USAGE.md 최신화 확인 [P4-05] 3) 5인 동시접속 테스트 실행 [P4-03] |

## Final Completion Gate
- [ ] 모든 체크리스트 ID가 Done 상태
- [ ] 모든 Done 항목에 Commit(s) 존재
- [ ] README, AI_USAGE 최신화
- [ ] 데모 리허설 완료
- [ ] 평가 기준(Function-First) 충족
