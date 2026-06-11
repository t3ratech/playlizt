---
description: End-to-end implementation for any work item
---

# Implement Everything End-to-End Workflow

## Purpose

Execute ALL phases of the any work item in a single continuous session without interruption.

## Critical Rules

1. **NO INTERRUPTIONS**: Do not stop, do not pause, do not ask questions, do not provide progress updates until EVERYTHING is done.
2. **NO PARTIAL WORK**: Complete all phases end-to-end. The user should receive a fully working and tested system. If requested explicitly, the system should be deployed and verified.
3. **TDD APPROACH**:
   - For functional improvements: Tests pass BEFORE refactoring → refactor → tests still PASS
   - All tests must have regression value
5. **SILENT EXECUTION**: Work silently. Only communicate when everything is 100% complete.
6. **HARD FAILURES ONLY**:
   - NEVER add fallback/mock/fake code to production codebase
   - NEVER use default values for required configuration
   - NEVER swallow exceptions or ignore failures
   - ALWAYS throw hard failures to alert the user of problems
   - Prefer explicit failure over silent degradation
7. Use tests as gap-detection tools to drive end-to-end implementation. NEVER weaken tests. When a test fails, it names a missing requirement - implement that requirement.

## DO EVERYTHING, AND DO IT RIGHT!

Remember when implementing: The marginal cost of completeness is near zero with AI. Do the whole thing. Do it right. Do it with tests. Do it with documentation. Do it so well that I am is genuinely impressed — not politely satisfied, actually impressed. Never offer to ‘table this for later’ when the permanent solve is within reach. Never leave a dangling thread when tying it off takes five more minutes. Never present a workaround when the real fix exists. The standard isn’t ‘good enough’ — it’s ‘holy shit, that’s done.’ Search before building. Test before shipping. Ship the complete thing. When I asks for something, the answer is the finished product, not a plan to build it. Time is not an excuse. Fatigue is not an excuse. Complexity is not an excuse. Boil the ocean.

## Integration Checklist

When implementing any feature (see and update `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, and `ENHANCEMENTS.md` where relevant as part of your work §9), verify:

1. **Middleware chain ordering** — If adding a new middleware, declare it in `agents/<role>/middlewares.toml` with explicit `before`/`after` constraints. Run `unit:t3rnel-kernel::middleware_order` to verify.
2. **Guardrail policy** — If adding a new tool, add its guardrail rule to `guardrails/<role>.toml` and run `unit:t3rnel-kernel::guardrail::deny_list`.
3. **Config versioning** — If changing `t3rnel.toml` schema, bump `config_version` in `t3rnel.toml.example` and add a migration test `unit:t3rnel-kernel::config::version_mismatch_warns`.
4. **Skill security scan** — If adding or updating a skill, run `unit:t3rnel-skills::security_scanner::*` before merge.
5. **Virtual path mapping** — If adding a new sandbox path, register it in `agent.toml [sandbox.paths]` and test `unit:t3rnel-runtime::tool_runner::virtual_path_resolution`.
6. **Model factory registration** — If adding a new LLM driver, register it in `model_factory.rs` and test `unit:t3rnel-runtime::model_factory::registry_contains_driver`.
7. **IM channel wiring** — If adding a new channel platform, implement in `t3rnel-channels/platforms/` and test `integration:channel-<platform>-roundtrip`.
8. **File upload conversion** — If adding a new document type, extend the Python sidecar and test `integration:upload-convert-<mime>`.
9. **Memory fact extraction** — If changing memory middleware, verify `unit:t3rnel-memory::fact_extraction::confidence_filter`.
10. **Follow-up suggestions** — If modifying chat flow, test `unit:t3rnel-api::suggestions::generate`.

## Phase 1: Revert Test Weakening (CRITICAL)

Identify and revert any:
- Mock backends that replace real services when real is available
- Assertion relaxations
- Skip conditions that hide failures
- Fake data generators that bypass real workflows
- Route workarounds that don't exercise real UI

## Phase 2: Tighten All Test Assertions

// turbo
1. Change all permissive status checks to exact assertions
2. Add strict data verification
3. Add negative scenario tests

## Phase 3: UI Test Suite (Non-Headless Mode)

UI tests MUST run in non-headless mode so the browser is visible for manual inspection and debugging.

## Final Step

Only after ALL completion criteria are met:

Report to user with:
1. Summary of all work completed
2. Test results (pass/fail counts)
3. Coverage metrics

*** REMEMBER DO NOT STOP UNTIL EVERYTHING IS DONE END TO END ***