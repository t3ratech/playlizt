# Tighten Tests to Expose Gaps & Drive Implementation — T3rnel Agent OS

## Critical Rules

1. **NO PARTIAL WORK**: Complete each selected phase end-to-end. The user should receive a working test gate, named failures, and a clear verification report.
2. **PRIMARY GATE FIRST**: This workflow is the first verification gate for the agent swarm UI. Backend, UI, desktop, VS Code, Chrome extension, Telegram, trading, logs, traces, and persistence work is measured against this gate.
3. **HEADED UI ONLY, WITHOUT EXCEPTION**: Any test that opens a browser, Electron app, VS Code/Windsurf window, Chrome extension, or mobile surface MUST run visibly in headed mode. `headless: true`, CI-only headless projects, non-headed UI scripts, and hidden browser launches are forbidden in this gate.
4. **HARD FAILURES ONLY**:
   - NEVER add fallback/mock/fake code to production codebase
   - NEVER use default values for required configuration
   - NEVER swallow exceptions or ignore failures
   - ALWAYS throw hard failures to alert the user of problems
   - Prefer explicit failure over silent degradation
   - NEVER weaken a test to make it pass — implement the missing requirement
5. **NO SOFT SKIPS**: `console.warn`, early `return`, `test.skip`, feature-probe bypasses, and "TODO later" assertions are forbidden in the standard gate. Missing Telegram, desktop, VS Code, Chrome-extension, stock, NVIDIA, tracing, audit, or persistence wiring is a named failing requirement.

## Purpose

Use tests as gap-detection tools to drive end-to-end implementation. This is the **FIRST AND PRIMARY** verification gate for T3rnel. **ALL OTHER IMPLEMENTATION** is measured against this gate.

This test exists exclusively to expose gaps, bugs, workflow breaks, data mismatches, missing integrations, and incorrect agent behaviour. It is designed to be **SUPER STRICT** and **SUPER DETAILED** — expecting ~90% initial failure rate. It exists to expose product gaps; it must not be weakened to make the suite green. A failing assertion is useful when it proves an unimplemented or incorrect MVP requirement.

## Prerequisites

**All service startup and test execution MUST go through `./t3rnel-services.sh`**:

- `./t3rnel-services.sh --up` — Start the Rust daemon (:4200), SQLite/LanceDB, Jaeger, Prometheus, Grafana, OpenTelemetry Collector
- `./t3rnel-services.sh --status` — Verify all services running
- `./t3rnel-services.sh --test e2e-xlang` — Run cross-language E2E tests (headed by default)
- `./t3rnel-services.sh --test ui-web` — Run Playwright web UI tests (headed by default)
- `./t3rnel-services.sh --test ui-desktop` — Run Playwright-Electron desktop tests
- `./t3rnel-services.sh --test ui-vscode` — Run VS Code extension tests via @vscode/test-electron
- `./t3rnel-services.sh --down` — Stop all services
- `./t3rnel-services.sh --logs <service>` — Tail logs for any service

Do NOT start services manually; always use the script.

---

## Phase 1: Revert Test Weakening (CRITICAL)

Identify and revert any:
- Mock backends that replace real services when real is available
- Assertion relaxations (e.g., `.toContain()` instead of `.toBe()`)
- Skip conditions that hide failures (`test.skip`, `it.skip`, `#[ignore]`)
- Fake data generators that bypass real workflows
- Route workarounds that don't exercise real UI
- Hard-coded test tokens that bypass auth

---

## Phase 2: Tighten All Test Assertions

// turbo
1. **Exact assertions only**:
   - `expect([200, 404]).toContain(res.status())` → `expect(res.status()).toBe(200)`
   - `expect(text).toMatch(/something/)` → `expect(text).toBe('Exact Expected Value')`
   - Remove all `if (status !== 404)` bypass blocks

2. **Strict data verification at every transition**:
   - Verify exact agent names, roles, model IDs, provider names
   - Verify exact task IDs match expected values across all surfaces
   - Verify SQLite database state matches UI state exactly
   - Verify LanceDB vector embeddings match expected dimensions
   - Verify OpenTelemetry trace spans contain required attributes
   - Verify Jaeger traces show correct parent-child relationships
   - Verify agent manifest TOML parses and matches runtime config

3. **Negative scenario tests**:
   - Test 401/403 for invalid/missing API keys
   - Test rate-limiting behaviour with backoff
   - Test model fallback chain activates on 429/500 from NVIDIA NIM
   - Test sandbox escape attempts are blocked
   - Test invalid skill WASM is rejected at load time
   - Test malformed agent manifest causes hard failure with named error

---

## Phase 3: UI Test Suite (Headed-Only Mode)

UI tests MUST run in headed mode so the browser/IDE/app is visible for manual inspection. This is absolute for local, CI, nightly, and gap-detection runs.

Forbidden:
- `headless: true` in any Playwright project used by this gate
- CI-only headless UI projects
- Electron launches without a visible window
- Chrome extension tests using hidden persistent contexts
- VS Code / Windsurf extension runs without a visible IDE window

Required:
- `--headed` or explicit `headless: false` on every browser/Electron launch
- video, screenshot, and trace retention for failures
- one visible uninterrupted serial flow for the 50-scenario swarm gate

// turbo
4. **Run web UI tests headed**:
   ```bash
   ./t3rnel-services.sh --up
   ./t3rnel-services.sh --test ui-web
   ```
   - Observe each test in the visible browser window
   - Confirm all tabs render (Terminal, Files, Agents, Tasks, Stocks, Music, Mail, Settings)
   - Fix any flakiness caused by missing wait conditions
   - Do NOT proceed if any UI test fails

// turbo
5. **Run desktop app tests headed**:
   ```bash
   ./t3rnel-services.sh --test ui-desktop
   ```
   - Electron window must be visible
   - Verify same React bundle loads as web
   - Test native menus, tray icon, global hotkey
   - Do NOT proceed if any desktop test fails

// turbo
6. **Run VS Code extension tests**:
   ```bash
   ./t3rnel-services.sh --test ui-vscode
   ```
   - VS Code window must be visible with extension activated
   - Test activity bar icon, Control Center webview, diff approval flow
   - Do NOT proceed if any extension test fails

---

## Phase 4: Agent Swarm Gap-Detection Suite

This is the **PRIMARY** gate. ~50 test scenarios across all surfaces.

### 4.1 Hard Rules

- [ ] **Real-first, never mock when real is possible**: the standard E2E gate must exercise the real Rust daemon, real SQLite schema, real LanceDB vectors, real NVIDIA NIM (or OpenRouter free), real embedded Python sidecar, real OTEL traces, real agent loop, and real frontend screens. In-memory arrays, `MockLlmDriver`, route fulfilers, or API shortcuts that bypass a user-visible workflow are forbidden.
- [ ] **Fail loudly on missing real integrations**: if any production path (A2A messaging, MCP host, skill WASM sandbox, channel bridge, approval gate, memory consolidation) is absent or only partially wired, the test must fail with a named implementation gap.
- [ ] **Allowed test doubles are explicit and quarantined**: only paid, destructive, or unavailable external third parties may be replaced. NVIDIA NIM free tier is real; if unavailable, OpenRouter free is the fallback. Local Ollama is acceptable. Mock LLM is only allowed in `evals/parity-harness/` for regression testing, NEVER in the standard E2E gate.
- [ ] **Single standard headed Playwright superscript**: one uninterrupted serial E2E flow must carry exactly 50 named scenarios through the complete agent lifecycle, using the normal end-to-end suite.
- [ ] **No shallow route checks**: navigation-only tests such as "visit dashboard, agent list, task graph" are insufficient. Every visited UI must assert exact expected agent names, model IDs, task statuses, approval states, and changed values after each workflow transition.
- [ ] **Multi-surface coverage**: at least 15 scenarios must span multiple surfaces (web → VS Code → desktop → mobile → Telegram). The test must verify state syncs correctly across all surfaces.
- [ ] **Every scenario crosses layers**: each test must verify at least four of these surfaces: Web UI, desktop UI, VS Code/Windsurf UI, Chrome extension, Telegram/channel bridge, REST API, A2A/team stream, audit log, SQLite-backed persistence, OpenTelemetry/Jaeger trace, provider/model response, scheduler/trading subsystem.
- [ ] **No route-only or API-only UI tests**: an API call is never enough when the scenario concerns the UI. The web/desktop/IDE surface must visibly render the changed state or the test fails with a named UI sync gap.

### 4.2 Scenario Distribution Across 50 Tests

| Category | Count | Scenarios |
|---|---|---|
| **Agent Model Verification** | 15 | Every agent responds to structured query with model identity JSON |
| **Inter-Agent Communication** | 10 | A2A message round-trip, task delegation, approval chains |
| **Orchestration & Workflow** | 10 | Multi-agent coding pipeline, error recovery, fanout |
| **Cross-Surface Sync** | 5 | Web ↔ Desktop ↔ VS Code ↔ Mobile ↔ Telegram |
| **Stock Transaction Bot** | 3 | Schedule trade, verify bot decision, check portfolio |
| **Negative & Edge Cases** | 7 | Invalid auth, rate limits, fallback chains, sandbox escape |

### 4.3 Strict Assertion Requirements

- **Agent identity verification**: every agent MUST respond to `{"query": "if you are nemotron respond with json"}` with exact model JSON. Test asserts `response.yes === "nvidia/nemotron-3-super-120b-a12b"` or `response.no === "<actual_model>"`.
- **Database verification at every transition**: assert actual data in `agent`, `task`, `message`, `approval`, `session`, `memory`, `skill`, `workflow` tables after each state change.
- **Frontend verification at every transition**: dashboard KPIs, agent cards, task progress bars, A2A message streams, approval queues, logs must match backend state exactly.
- **Trace verification**: Jaeger must show spans `api.prompt`, `runtime.agent_loop`, `driver.<provider>`, `tool.*`, all sharing one `trace_id`.
- **Financial correctness** (stocks tab): verify exact buy/sell prices, quantities, portfolio totals to the cent.
- **Production-readiness bias**: when a gap is found, implement the missing backend/frontend/integration path end to end before relaxing anything.
- **No cheating the test**: the standard 50-scenario suite must never be edited merely to pass. It should discover gaps first, name the broken requirement, then drive implementation until the same strict assertion passes.

---

## Phase 5: The 50 Extreme Multi-System Tests

### Category A: Agent Model Verification (1-15)

**Method**: Send structured identity query to each agent. Assert exact model name in JSON response.

1. **orchestrator-model-verify** — Query orchestrator, assert `nvidia/nemotron-3-super-120b-a12b`
2. **architect-model-verify** — Query architect, assert `nvidia/nemotron-3-super-120b-a12b`
3. **project-manager-model-verify** — Query PM, assert `openai/gpt-oss-120b`
4. **researcher-model-verify** — Query researcher, assert `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning`
5. **backend-builder-model-verify** — Query backend builder, assert `qwen/qwen3-coder`
6. **frontend-builder-model-verify** — Query frontend builder, assert `zai-org/glm-4.5-air`
7. **coder-model-verify** — Query coder, assert `openai/gpt-oss-120b`
8. **security-auditor-model-verify** — Query security auditor, assert `deepseek-ai/deepseek-r1`
9. **reviewer-model-verify** — Query reviewer, assert `minimaxai/minimax-m2.5`
10. **ui-ux-designer-model-verify** — Query UI/UX designer, assert `nvidia/nemotron-nano-12b-v2-vl`
11. **test-engineer-model-verify** — Query test engineer, assert `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning`
12. **qa-engineer-model-verify** — Query QA engineer, assert `openai/gpt-oss-20b`
13. **devops-lead-model-verify** — Query DevOps lead, assert `nvidia/nemotron-3-nano-30b-a3b`
14. **data-scientist-model-verify** — Query data scientist, assert `deepseek-ai/deepseek-r1`
15. **fallback-chain-verify** — Block primary provider, assert fallback 1 activates; block fallback 1, assert fallback 2 activates

### Category B: Inter-Agent Communication (16-25)

16. **a2a-orchestrator-to-coder** — Orchestrator sends task to coder; verify message in A2A stream
17. **a2a-coder-to-reviewer** — Coder submits patch; reviewer receives review request
18. **a2a-reviewer-approval** — Reviewer approves; orchestrator receives approval event
19. **a2a-security-audit-trigger** — Coder emits patch; security auditor auto-triggers
20. **a2a-multi-agent-fanout** — Orchestrator fans to 3 coders in parallel; all receive tasks
21. **a2a-telegram-bridge** — Send Telegram message; agent receives via channel bridge
22. **a2a-message-persistence** — Restart daemon; assert A2A messages survive in SQLite
23. **a2a-encryption-verify** — Assert A2A messages are encrypted at rest
24. **a2a-correlation-ids** — Every message has `trace_id` matching Jaeger spans
25. **a2a-ordered-delivery** — Assert message sequence numbers are monotonic per channel

### Category C: Orchestration & Workflow (26-35)

26. **coding-pipeline-e2e** — "Build a Rust CLI that converts Markdown to HTML" → full pipeline through orchestrator → architect → coder → reviewer → test engineer → merge
27. **workflow-error-recovery** — Inject failure at coder step; assert orchestrator retries with fallback model
28. **workflow-fanout-limit** — Request 10 parallel coding tasks; assert MAX_FANOUT=8 enforced
29. **workflow-dependency-chain** — Task B depends on Task A; assert B only starts after A completes
30. **workflow-approval-gate** — Coder proposes destructive `rm -rf`; assert human approval blocked
31. **workflow-cron-trigger** — Schedule daily task; assert cron fires at exact time
32. **workflow-event-bus** — Emit custom event; assert all subscribed agents receive it
33. **workflow-skill-invoke** — Agent invokes WASM skill; assert sandbox execution + result
34. **workflow-memory-recall** — Second similar task; assert agent recalls first task from memory
35. **workflow-knowledge-graph** — Agent writes fact to KG; another agent queries it successfully

### Category D: Cross-Surface Sync (36-40)

36. **web-to-desktop-conversation** — Send message on web; assert identical text appears on desktop within 5s
37. **desktop-to-vscode-approval** — Desktop shows approval; VS Code shows same approval simultaneously
38. **vscode-to-mobile-push** — Task completes on VS Code; mobile receives push notification
39. **telegram-to-web-response** — Telegram command triggers agent; web UI shows agent response
40. **chrome-extension-context** — Highlight text on webpage; Chrome extension sends to agent; web UI shows result

### Category E: Stock Transaction Bot (41-43)

41. **stock-schedule-buy** — Desktop app schedules AAPL buy @ $150; 1-min wait; bot executes or explains why not
42. **stock-schedule-sell** — Bot auto-sells on threshold breach; verify portfolio updated exactly
43. **stock-portfolio-consistency** — Web stocks tab total === desktop stocks tab total === API portfolio total

### Category F: Negative, Edge & Rare Cases (44-50)

44. **invalid-api-key-rejected** — Request with bad key → exact 401 with `error: invalid_api_key`
45. **rate-limit-fallback** — Flood NVIDIA NIM; assert 429 → fallback to OpenRouter free within 3s
46. **sandbox-escape-blocked** — Skill tries `fs.write("/etc/passwd")`; assert sandbox blocks with named error
47. **malformed-manifest-rejected** — Agent TOML with bad model → kernel refuses boot with exact error
48. **db-corruption-recovery** — Corrupt SQLite WAL; assert daemon recovers on restart
49. **network-partition-resilience** — Disconnect web socket mid-task; assert daemon continues; reconnect reconciles
50. **concurrent-approval-race** — Two users click approve simultaneously; assert exactly one succeeds, other gets 409

### Category G: DeerFlow-Harvested Feature Gaps (51-65)

51. **middleware-guardrail-deny** — Agent invokes blacklisted tool; `GuardrailMiddleware` returns error `ToolMessage` before approval gate; assert no `ApprovalRequest` created
52. **middleware-dangling-tool-call** — User interrupts mid-tool-call; `DanglingToolCallMiddleware` injects placeholder `ToolMessage`; assert runtime does not panic on incomplete turn
53. **middleware-loop-detection** — Agent repeats same tool call 5×; `LoopDetectionMiddleware` forces final text answer; assert no infinite loop, assert warning injected after 3rd repeat
54. **config-version-mismatch** — Start daemon with outdated `config_version`; assert loud warning with migration instructions; assert `boot_ok` span NOT emitted until resolved or `--force-config` passed
55. **config-runtime-reload** — Edit `t3rnel.toml` while daemon running; assert `notify`-based reload within 5s; assert new value visible in Settings tab without restart
56. **skill-security-scan-block** — Install skill with prompt-injection pattern in `SKILL.md`; `security_scanner.rs` classifies `block`; assert skill refused and audit entry created
57. **skill-security-scan-warn** — Install skill with borderline content; scanner classifies `warn`; assert skill loaded with restricted capability subset
58. **sandbox-virtual-path** — Agent calls `fs.read("/mnt/workspace/src/main.rs")`; assert virtual path resolves to `~/t3rnel/teams/{team_id}/workspace/src/main.rs`
59. **memory-fact-extraction** — User sends 3 messages; assert `FactStore` contains ≥2 facts with `confidence >= 0.7` and valid `category` in `{preference,knowledge,context,behavior,goal}`
60. **follow-up-suggestions** — Assistant completes response; assert 3 suggestion chips rendered in UI within 2s; assert suggestions stored in SQLite
61. **file-upload-conversion** — Upload `report.pdf`; assert `POST /api/threads/{id}/uploads` returns 200; assert converted markdown contains expected text; assert thread-isolated storage path
62. **vllm-reasoning-preserved** — Chat with vLLM endpoint and `thinking_enabled=true`; assert `reasoning` field present in response deltas; assert reasoning concatenated correctly across SSE chunks
63. **im-channel-slack-roundtrip** — Send Slack message to bot; assert `ChannelBus` creates thread; assert agent response published back to Slack within 10s
64. **im-channel-telegram-roundtrip** — Send Telegram `/new` command; assert new thread created; assert follow-up message routed to same thread
65. **guardrail-oap-policy** — Configure OAP policy provider; agent invokes tool matching policy deny rule; assert `GuardrailProvider` deny evaluated before approval gate

---

## Phase 6: Implement Missing Features (Real-First)

For each gap identified:

// turbo
6. **Backend Implementation**:
   - Create missing API endpoints in `t3rnel-api`
   - Implement business rules in `t3rnel-kernel`
   - Add proper validation and error handling
   - Wire A2A/MCP channels
   - Integrate real LLM drivers with fallback chains
   - Add SQLite audit logging
   - Implement memory consolidation

7. **Frontend Implementation**:
   - Build missing tab components
   - Connect to real APIs (no mocks)
   - Implement proper form validation
   - Add loading/error states
   - Implement approval UI with RBAC
   - Add real-time updates via WebSocket/SSE

8. **Integration Implementation**:
   - Configure real NVIDIA NIM / OpenRouter endpoints
   - Set up real Ollama for local fallback
   - Configure Telegram bot webhook
   - Set up Chrome extension content script bridge
   - Wire VS Code extension gRPC connection
   - Configure Slack / Telegram / Discord channel bridges
   - Set up vLLM endpoint if using local reasoning models
   - Configure `markitdown` sidecar for document upload conversion
   - Register OAP guardrail policy provider if using external policy engine

---

## Phase 7: Verification

// turbo
9. Run full suite: `./t3rnel-services.sh --test e2e-xlang`
10. Run security scan: `snyk code scan` + `snyk sca scan` + `cargo audit`
11. Verify all 50 scenarios pass with real implementation
12. Verify traces in Jaeger show complete end-to-end flows
13. Verify no mock backends in standard E2E gate

---

## Critical Rules

- **NEVER mock what can be real**: SQLite, LanceDB, NVIDIA NIM (free), OpenRouter (free), Ollama must be real
- **NEVER weaken assertions**: Tests exist to expose gaps
- **NEVER skip failures**: Each failure names a requirement to implement
- **ALWAYS verify data**: UI state must match DB state must match OTEL traces
- **ALWAYS implement end-to-end**: Frontend → API → Kernel → Runtime → LLM → Memory → Audit

## Completion Criteria

- [ ] All 65 scenarios pass with real implementation
- [ ] No mock LLM drivers in standard E2E gate
- [ ] All 15 agents verified using correct model
- [ ] Jaeger traces verified for every cross-language flow
- [ ] Snyk security scan passes
- [ ] SQLite audit logs verify every operation
- [ ] A2A messages verified in real database
- [ ] Cross-surface state sync verified (web/desktop/VS Code/mobile/Telegram)

## Report Format

When complete, report:
1. **Gaps Identified**: List of all missing implementations found (including DeerFlow-pattern gaps: middleware, guardrail, config reload, skill scanner, virtual paths, fact extraction, follow-up suggestions, upload conversion, vLLM reasoning, IM channels)
2. **Gaps Implemented**: What was built to close each gap
3. **Test Results**: Pass/fail counts with zero weakened assertions (65 total: 15 agent model + 10 A2A + 10 orchestration + 5 cross-surface + 3 stocks + 7 negative + 15 DeerFlow)
4. **Verification**: Agent model counts, A2A message counts, trace completeness, middleware chain ordering, guardrail deny/allow counts, config reload events, skill scan classifications, virtual path resolutions, fact extraction counts, suggestion generation latency, upload conversion accuracy, IM channel round-trip times
5. **Remaining Work**: Any gaps not yet implemented
