---
description: End-to-end production hardening — audit, reason as the real user, fill every gap, test deeply, document, audit again, commit & push. No questions, no stopping.
---

# /ship-to-production

Take an AI-built project that *claims* to be done and make it genuinely production-ready. AI built this and left gaps while reporting "100% working." Treat that claim as false until proven by evidence. This workflow SUPERSEDES all others.

## PRIME DIRECTIVE
Run every phase below in ONE continuous session. Do NOT stop, pause, ask questions, or post progress updates until the FINAL REPORT. Work silently. End only at: (a) shipped & pushed with a GO verdict, or (b) NO-GO with every blocker documented and fixed-or-proven-impossible.

## LAWS (apply to every phase)
1. **Evidence over assertion.** Nothing is "working" until proven by an artifact: a passing test, a real DB query result, a screenshot, a log line, an HTTP response. "I clicked it and saw no error" is NOT evidence and is forbidden as a success criterion.
2. **Predict, then verify.** Before every action, write the expected outcome on THREE planes — UI (what the user sees), DATA (exact rows/values in the physical DB), LOGS/STATUS (what gets recorded). After the action, verify all three. A pass on UI with wrong DB state is a FAILURE.
3. **Reason as the user, not as a clicker.** For every screen and action ask: "Does a real person doing their real job accomplish their goal here, in the sequence they'd actually do it?" Navigating by typing a URL, using a route with no menu/button, or scrolling away from a screen the user can't leave = the feature is MISSING, not present. E.g. a call-center agent on a live call cannot navigate away — debtor info must be reachable from the call screen (button → modal) AND from a real menu entry.
4. **Missing affordances are DEFECTS, not enhancements.** No back button, no search where a record must be found, no filter/sort on a long list, no export where data must leave, hard-coded values that should be configurable, or machine codes shown instead of human labels (raw symbol codes vs ticker names) — log each as a defect and FIX it. Infer these from the user's job; you do not need to be told.
5. **Hard failures only.** Never add mock/fake/fallback/sample code, default values for required config, or swallowed exceptions to the production codebase. Loud explicit failure beats silent degradation. Real services where real services exist.
6. **No stubs ship.** Zero `TODO`/`FIXME`/`HACK`/`NotImplemented`/"not implemented"/`placeholder`/`stub`/`mock` (outside test fixtures), debug logging, commented-out blocks, or dead code in production paths.
7. **Tests are gap detectors; never weaken them.** A failing test names a missing requirement — implement it. Never relax an assertion, add a skip, widen a status check, or fake data to make a test pass.
8. **Boil the ocean.** Marginal cost of completeness is near zero. Do the whole thing, right, with tests and docs. Never table for later, never workaround when the real fix is reachable, never leave a dangling thread. The bar is "holy shit, that's done," not "good enough."

## PHASE 0 — Ground Truth
// turbo
1. Read everything: all source, config, schema, migrations, and every doc (`README*`, `ARCHITECTURE*`, spec, `IMPLEMENTATION_PLAN*`, `ENHANCEMENTS*`). Derive state from source + a running system only; trust no "done" claim.
2. Build and run end-to-end (install, migrate, seed, start every service). If it does not build/run/migrate cleanly, that is defect #1.
3. Create `docs/PRODUCTION_AUDIT.md` — the running ledger. Sections: System Purpose, Personas, Journeys, Gap Ledger (table: ID | dimension | location | severity | evidence | fix | status), Test Plan, Coverage, Final Verdict. Append continuously; it holds the verbose detail so this workflow stays terse.

## PHASE 1 — Purpose & Personas
1. Write one paragraph on what this system is FOR and its domain (call center, trading, EHR…), inferred from code + docs.
2. Enumerate every persona (trader, agent, admin, auditor…) with their real-world goals and constraints.
3. For each persona, map their full real-world JOURNEY as numbered steps — the complete sequence they'd actually perform. Depth expected:
   - Trader: log in → pick instrument (shown by ticker name, not symbol code) → see charts/history/indicators → place order (size, multiplier) → balance/equity update → open positions → track live P/L → modify TP/SL → partial & full manual close → realized P/L hits balance → history (cost, open/close time, multipliers, fees) → export.
   - Agent: receive a call → debtor data reachable WITHOUT leaving the call screen → log outcome → next call in sequence.
4. These journeys are the acceptance spec. Any step a real user needs that the system cannot do is a defect — log it.

## PHASE 2 — Persona Journey Walkthrough (the core test)
Walk each journey step-by-step in the running app, applying Laws 2–4 at EACH step:
- State expected UI/DATA/LOGS; perform the step only via controls a user can actually reach; verify all three planes; query the physical DB to confirm.
- At every screen, log gaps in: navigation (menu entry? back button? breadcrumb?), discoverability (search/filter/sort where needed?), data friendliness (human labels not codes; right units; locale formatting), missing actions this role needs (buttons/modals), configurability of hard-coded values, empty/error/loading states, dead-ends or URL-typing.
- Open the browser console and network tab on every page: any console error or swallowed 4xx/5xx is a defect.
Log every finding to the Gap Ledger with severity.

## PHASE 3 — Multi-Dimensional Audit
Sweep the whole system for each dimension; log every gap (Phase 4 fixes them).
- **Completeness:** grep for the Law-6 markers; each hit is a defect. No half-built features.
- **Security & authz:** auth on every protected route; RBAC enforced server-side; test IDOR (user A cannot touch user B's records by ID); input validation; injection (SQL/XSS/command); no secrets/keys in source or client bundles; TLS in transit + encryption at rest for sensitive data; secure session/cookie/CORS; rate limiting on auth & money endpoints.
- **Deep data accuracy:** on EVERY create/update/delete, query the physical DB and assert the row matches intent; verify audit/log entries written; verify computed values with explicit equation checks (equity = balance + unrealized P/L; total = Σ line items; realized P/L on close). Money uses fixed-precision decimals (never floats), consistent decimals, correct rounding. Referential integrity & transactional atomicity (no partial writes). Timestamps UTC.
- **Consistency:** one storage format and one display format per data type app-wide — phone numbers E.164, money to a single decimal precision stored and displayed, dates/times one format, IDs/enums uniform. Fix every divergence.
- **Compliance:** locale-correct number/date/currency formatting; required domain disclosures/labels; encryption meets the domain bar; sane data-retention/PII handling.
- **UX & quality:** logical flow, consistent layout/components, readable type & contrast, sensible defaults, confirmation on destructive actions, no truncated/overlapping content, responsive.
- **Accessibility:** keyboard nav, focus order, labels/alt text, WCAG AA contrast.
- **Observability & performance:** structured logs on key actions & errors, metrics, meaningful surfaced errors, no silent failures; no N+1 queries, indexes on filtered/joined columns, pagination on unbounded lists, acceptable response times at realistic volume.
- **Resilience & concurrency:** explicit (not silent) timeouts/retries on external calls; idempotency on money/submit actions (double-submit safe); concurrent-edit races handled.

## PHASE 4 — Implement Every Gap (TDD, hard failures)
For each ledger item, security & data-correctness first:
1. Write a test that fails because the requirement is missing (Law 7).
2. Implement the real fix — feature, button, modal, menu entry, filter, export, config option, validation, schema/migration — to production standard (Laws 5–6).
3. Make the test pass without weakening it. Re-run the journey step; re-verify all three planes + DB.
4. Integration wiring after any change: register new routes in the real navigation/menu; set middleware order with explicit before/after and verify; add deny-by-default authz on new endpoints; bump config schema version + add a version test if config changed; register new drivers/handlers in their factories with a registry test; add reversible, tested DB migrations.
5. Close the item with its evidence. Do not advance while any item is open.

## PHASE 5 — Comprehensive Test Suite
Build the full pyramid; normal AND negative path for every UI and every backend endpoint.
- **Unit:** business logic, calculations, validators, edge/boundary values, error paths.
- **Integration:** real service/DB interactions; every endpoint incl. authz-denied and bad-input cases; every CRUD asserts physical DB state and audit-log writes.
- **UI / E2E:** the Phase 1 persona journeys as automated tests, asserting UI + DB + logs at each step. **Run UI tests NON-HEADLESS (visible browser).**
- **Negative everywhere:** invalid input, unauthorized access, missing/expired data, concurrency, double-submit, network failure — assert loud, correct failure.
- **Regression:** every fixed bug gets a permanent guarding test.
- **Efficiency:** maximize coverage but consolidate overlap — one journey E2E can assert UI + DB + audit + calculation at once. Don't duplicate trivial unit tests; never weaken to merge.
- Run the FULL suite. Generate a coverage report; record it; raise coverage toward the practical maximum, prioritizing untested critical/security/money paths. All green before Phase 6.

## PHASE 6 — Documentation & Shipping Artifacts
Update to match the now-true system, in **present-tense, declarative, system-subject voice** (no "we/I", no historical/transitional phrasing, no status labels like Done/WIP/Planned outside an explicit Timeline section). Zero information loss; merge duplicates keeping the fullest version; regenerate any ToC last with working anchor links.
- `ARCHITECTURE.md`, spec, `IMPLEMENTATION_PLAN.md`, `ENHANCEMENTS.md`: reflect what now exists.
- `README`: accurate setup/run/test/deploy, prerequisites, env vars. Plus `.env.example` (every required var, no real secrets), `CHANGELOG`, a deploy/runbook with rollback, and API docs if endpoints changed.

## PHASE 7 — Final Production Audit (adversarial)
Act as a hostile senior reviewer who does NOT trust earlier phases.
1. Re-derive readiness from scratch: clean build + migrate + full test suite from zero — all green.
2. Confirm EVERY ledger item closed with evidence. Re-grep for Law-6 markers — zero hits.
3. Re-walk one complete persona journey live, verifying UI + DB + logs at each step.
4. Production checklist (all must hold): builds clean; all tests pass; coverage recorded; no stubs/secrets/console errors; authz + IDOR safe; money/data correctness proven against DB; formatting uniform; docs accurate; migrations reversible; observability present.
5. Write a GO / NO-GO verdict with justification. **If NO-GO, return to Phase 4 — do not ship, do not end the session.** Loop until GO.

## PHASE 8 — Commit & Push (only on GO)
// turbo
1. Stage and commit in logical units with conventional messages (`feat:`/`fix:`/`test:`/`docs:`/`refactor:`).
2. Push to the current branch's remote.

## FINAL REPORT (first and only message to the user)
1. System purpose & personas covered.
2. Gaps found and fixed, grouped by dimension, with counts.
3. Test results: pass/fail per layer + coverage %.
4. Notable features/affordances added that were never explicitly requested (and why the role needs them).
5. Docs updated; final audit verdict (GO/NO-GO); commit/push result.
