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
| P2-01 | Authentication: signup/login/profile update E2E |  | TODO |  |  |  |
| P2-02 | Password hashing and salting verification in DB | hijae | Done | auth.service.ts | test_auth.sh E2E signup test | feat(auth): implement signup api with password hashing [#7] [P2-02] |
| P2-03 | Basic Acid Rain typing battle gameplay loop complete | yuhyoon | Done | GAME_DESIGN.md, WEBSOCKET_PROTOCOL.md | 산성비 게임 흐름 문서 검토 | backend#72, backend#75, deploy#65 |
| P2-04 | WebSocket real-time sync for game state |  | TODO |  |  |  |
| P2-05 | Chat messaging latency target (<1s) validated |  | TODO |  |  |  |
| P2-06 | Friend system flow: add/accept/status update |  | TODO |  |  |  |

---

## Phase 3. Advanced Modules (Week 5-6)

| ID | Task | Owner | Status | Implementation Evidence | Validation Evidence | Commit(s) |
|---|---|---|---|---|---|---|
| P3-01 | Remote players match flow stable under reconnect |  | TODO |  |  |  |
| P3-02 | AI opponent card strategy logic complete |  | TODO |  |  |  |
| P3-03 | Match result persistence and score history integrity | yuhyoon | Done | game.service.ts (recordMatchHistory) | game-engine.spec.ts game-over tests | feat(game): implement game over logic, match persistence, and redis teardown [P3-03] |
| P3-04 | Prometheus metrics exposed and scraped |  | TODO |  |  |  |
| P3-05 | Grafana dashboard with CPU/memory/network panels |  | TODO |  |  |  |
| P3-06 | Monitoring alert rule smoke test complete |  | TODO |  |  |  |

---

## Phase 4. Hardening and Evaluation Readiness (Week 7-8)

| ID | Task | Owner | Status | Implementation Evidence | Validation Evidence | Commit(s) |
|---|---|---|---|---|---|---|
| P4-01 | Browser console warning/error zero baseline |  | TODO |  |  |  |
| P4-02 | Privacy Policy and Terms of Service page reachable |  | TODO |  |  |  |
| P4-03 | Multi-user concurrency check (>5 users) completed |  | TODO |  |  |  |
| P4-04 | README module-to-owner and demo flow finalized |  | TODO |  |  |  |
| P4-05 | AI_USAGE transparency and review log finalized |  | TODO |  |  |  |
| P4-06 | Final demo script and fallback scenario rehearsed |  | TODO |  |  |  |

---

## Milestone Summary

| Phase | Done | In Progress | Blocked | TODO |
|---|---:|---:|---:|---:|
| Phase 1 | 6 | 0 | 0 | 0 |
| Phase 2 | 2 | 0 | 0 | 4 |
| Phase 3 | 1 | 0 | 0 | 5 |
| Phase 4 | 0 | 0 | 0 | 6 |

## PM Weekly Review Log

| Date | Reviewer | Phase Reviewed | Missing IDs | Missing Commit Evidence | Top Risk | Next 3 Commits |
|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |

## Final Completion Gate
- [ ] 모든 체크리스트 ID가 Done 상태
- [ ] 모든 Done 항목에 Commit(s) 존재
- [ ] README, AI_USAGE 최신화
- [ ] 데모 리허설 완료
- [ ] 평가 기준(Function-First) 충족
