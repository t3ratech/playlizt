---
description: Run the enterprise-grade architectural audit, remediation and production hardening protocol before any release
---

# Enterprise Audit Workflow

Use this workflow before every production release (or when explicitly asked to audit the system). It is a single-session, zero-interruption, end-to-end execution protocol.

## Pre-conditions

- Ensure you have read access to the full repository.
- Confirm the audit mode with the user if unsure:
  1. **Pre-Launch Audit** (default) — full-sweep review before first production release
  2. **Continuous Dogfooding Review** — incremental per-PR / per-merge drift check
  3. **Business-Team Project Audit** — internal business team runs against their own product

## Report Output & Naming

All audit reports MUST be written to a consistent location and follow a strict naming convention:

- **Directory:** `audits/runs/<ISO-8601-timestamp>/`
  - Example: `audits/runs/2026-05-19T04-50-00Z/`
- **Filename:** `AUDIT_LOG_<LLM-FULL-NAME>_<YYYY_MM_DD>.md`
  - The LLM full name is the exact model identifier used for the audit (e.g., `KIMI_K2.6`, `CLAUDE_SONNET_4`, `NEMOTRON_3_SUPER_120B`).
  - Example: `AUDIT_LOG_KIMI_K2.6_2026_05_19.md`
- **Legacy `AUDIT_LOG.md` in repo root:** is a historical artifact. Do not overwrite it. New audits go into the dated run directory.
- **Per-run directory also contains:**
  - `findings/` — individual finding detail files
  - `remediation/` — patch files and evidence screenshots
  - `sbom/` — SBOM artifacts
  - `compliance/` — jurisdiction-specific compliance evidence

## Execution Rules

- **NEVER STOP.** Do not pause for clarifying questions, confirmation, or progress updates. Make defensible decisions, mark them `AUDIT-AMBIGUITY`, and continue.
- **Never add fallback / mock / fake code to production paths.** Fail fast, fail loud, fail with diagnostic context.
- **Tag every change with a risk tier:** SAFE | MEDIUM | HIGH | BREAKING.
- **Use `AUDIT-*` markers in code** (grep-able prefixes) and mirror every marker into `AUDIT_LOG.md`.
- **Respect the output location rules.** Never write audit logs, generated artifacts, or temporary files to the repository root.

## Document Generation Standards

All documents produced by this workflow (and all T3rnel documents going forward) MUST obey the following standards:

1. **Executive Summary First** — every user-facing document starts with a concise executive summary (3–5 bullets) stating: what this document is, why it matters, the key conclusion, and the recommended action.
2. **Table of Contents** — every document longer than one screen has a clickable table of contents with anchor links to each H2/H3 section.
3. **Tables over Prose** — wherever data is tabular (findings, comparisons, matrices, checklists), use a markdown table. Do not bury tabular data in paragraphs.
4. **Diagrams where helpful** — architecture, data flow, state machines, and decision trees should include Mermaid diagrams (```mermaid) or ASCII art when Mermaid is unavailable.
5. **No root-level log files** — all `.log`, `.jsonl`, `.txt`, and trace files go to `logs/` (or `logs/<subsystem>/`). The repository root is never a log dump.
6. **Temporary scripts in `scripts/tmp/`** — any one-off script, migration helper, or diagnostic tool created during the audit goes to `scripts/tmp/` with a dated prefix (e.g., `scripts/tmp/2026-05-19-fix-orphaned-tasks.py`). It is deleted or promoted to `scripts/` within 30 days.
7. **No plain text dumps** — never output unformatted lists of file paths, grep results, or stack traces as raw text blocks. Wrap them in code fences with language tags, or summarize them in tables.
8. **File naming convention:**
   - Markdown docs: kebab-case (e.g., `security-policy.md`)
   - Code/scripts: snake_case (e.g., `run_audit.py`)
   - Config: kebab-case for YAML/TOML, snake_case for JSON keys
   - Dates in filenames: `YYYY-MM-DD` (ISO 8601 short)
9. **Document versioning header** — every document has a version and last-reviewed date at the top:
   ```markdown
   <!-- doc-version: 1.2.0 | last-reviewed: 2026-05-19 | owner: architect -->
   ```
10. **No binary files in repo root** — images, PDFs, archives go to `assets/`, `public/assets/`, `docs/assets/`, or `artifacts/`.
11. **Generated artifacts** — build outputs, generated clients, compiled WASM go to `target/`, `artifacts/`, or `gen/` — never committed unless explicitly required.
12. **Config isolation** — runtime config files go to `config/`; environment-specific overrides to `config/environments/`. Root-level config only for standard tooling (`.gitignore`, `Cargo.toml`, `package.json`).
13. **Data files** — test fixtures to `tests/fixtures/`, seed data to `data/seeds/`, sample data to `data/samples/`.
14. **Consistent date format in content** — ISO 8601 (`2026-05-19T04:50:00Z`) for machine-readable, `19 May 2026` for human-readable prose.
15. **Every document has an owner** — the `owner:` field in the version header names the agent role responsible for keeping it current.

## Phase-by-Phase Execution

1. **Phase 0 — Discovery & Baseline**
   Produce a System Truth Document: inventory every entry point, data flow, external dependency, state store, config variable, trust boundary, business invariant, and operational topology. **Mandatory:** read and reconcile `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `README.md`, and `CHANGELOG.md` against each other and the source code. Produce a four-way document cross-reference matrix; flag every inconsistency as an audit finding. Write characterization tests before refactoring any non-trivial module.

2. **Phase 1 — Architectural Anti-Pattern Inventory**
   Document hidden coupling, circular dependencies, god classes, leaky abstractions, concurrency hazards, distributed-systems risks, and duplication. Verify that the System Truth Document from Phase 0 is consistent with the findings in this phase. Do not fix yet — just register findings with location, severity, risk tier, blast radius, and proposed remediation phase. Ensure that the document cross-reference matrix from Phase 0 is updated to reflect any new findings.

3. **Phase 2 — Test Scaffold Before Refactor**
   Write characterization tests pinning current behavior (including wrong behavior). Add regression tests for every bug you intend to fix. Enforce deterministic, isolated tests. Target coverage: critical path 90%+ line + branch, supporting modules 80%+.

4. **Phase 3 — Security Audit & Hardening**
   Audit OWASP Top 10, cryptography & identity, injection & input vectors, authorization architecture, resource safety, secret handling, supply chain, and trust boundary discipline. Never optimize insecure code.

5. **Phase 4 — Compliance & Regulatory Alignment**
   Map controls to Zimbabwe (CDPA, POTRAZ), South Africa (POPIA, RICA, ECTA), SADC regional, European Union (GDPR, NIS2, DORA, EU AI Act, eIDAS, ePrivacy), and United States (HIPAA, PCI-DSS, SOC 2, SOX, GLBA, CCPA/CPRA, FedRAMP, COPPA, CFAA, export controls). Produce a Compliance Matrix: regulation → article → control → code evidence → test evidence → risk if removed.

6. **Phase 5 — Technical Debt Eradication**
   Remove dead code, unused dependencies, duplicated logic, magic numbers, hardcoded values, and inconsistent patterns. Normalize naming, error handling, logging, DI, async patterns, and validation strategies across the codebase.

7. **Phase 6 — Comment & Documentation Sanitization**
   Strip historical / migration / debugging comments. Retain domain explanations, architectural intent, security-critical docs, concurrency reasoning, public API contracts, compliance-tagged comments, license headers, and `AUDIT-*` markers.

8. **Phase 7 — Architectural Reconstruction**
   Refactor toward Clean Architecture, Hexagonal / Ports & Adapters, SOLID, DDD, CQRS (where justified), Event-Driven Architecture (where justified), Twelve-Factor, and Secure-by-Design. Enforce strict separation of concerns, domain isolation, dependency inversion, and immutable contracts.

9. **Phase 8 — Performance & Scalability**
   Analyze algorithmic complexity, N+1 queries, memory churn, serialization overhead, and cache invalidation. Implement batching, pooling, cursor-based pagination, explicit cache invalidation, streaming, async pipelines, and concurrency-safe operations. Ensure horizontal scalability, graceful degradation, and resilience under load.

10. **Phase 9 — Reliability & Observability**
    Implement structured logging, correlation IDs, distributed tracing, RED/USE metrics, health checks (liveness / readiness / startup), circuit breakers, retry with jittered exponential backoff, graceful shutdown, backpressure, and bulkheads. Ensure logs are PII-redacted and operationally useful.

11. **Phase 10 — API & Contract Validation**
    Standardize OpenAPI / gRPC / AsyncAPI specs, DTO schemas, canonical serialization, RFC 7807 error responses, cursor-based pagination, correct status codes, versioning with deprecation policy, backward-compatibility rules, and idempotency guarantees.

12. **Phase 11 — Supply Chain & Dependencies**
    Audit for CVEs, abandoned packages, conflicting transitive deps, unused packages, and typosquats. Upgrade insecure dependencies. Generate SBOM (CycloneDX or SPDX). Validate reproducible builds, lock-file integrity, license compliance (zero copyleft contamination in proprietary dists), and signed artifacts. Target SLSA 3.

13. **Phase 12 — Distributed Systems Rigor**
    Make delivery semantics explicit per message type. Implement idempotency keys, outbox pattern, saga / compensation, clock-skew documentation, split-brain handling, explicit CP vs AP choices, end-to-end backpressure, replay safety, and poison-message handling with DLQ.

14. **Phase 13 — Cost / FinOps**
    Audit query cost, egress cost, log volume cost, idle resources, storage tiering, and cache hit ratios. Tag findings with order-of-magnitude impact. Never fabricate dollar figures.

15. **Phase 14 — Accessibility & Internationalization**
    Enforce WCAG 2.2 AA minimum, screen-reader compatibility, ICU MessageFormat, RTL support, locale-correct formatting, UTC storage with user-TZ display, and integer minor units for currency.

16. **Phase 15 — Testing & Quality**
    Add unit, integration, E2E, security, concurrency, property-based, mutation, contract, and migration tests. Assert failure paths as rigorously as success paths. Every fixed bug gets a regression test that fails on pre-fix code.

17. **Phase 16 — Production Release Hardening**
    Enforce production-safe config (required values throw at startup), environment isolation, secrets management, container hardening, CI/CD gates (SAST, DAST, SCA, secret scanning, IaC scanning, container scanning), blue/green or canary deployment, migration safety (expand-contract), startup validation, crash resilience, operational observability, and disaster recovery with tested restores.

18. **Phase 17 — Self-Review & Exit Criteria**
    Re-read your own output for regressions, broken invariants, new technical debt, orphaned `AUDIT-*` markers, `BREAKING` changes without migration paths, and unevidenced compliance controls. Fix each finding and re-run until clean. Verify the Definition of Done checklist.

19. **Phase 18 — Legal, Copyright, Trademark & OSS Compliance**
    Audit corporate identity, copyright notices, SPDX headers, OSS attribution (`NOTICE`, `third_party/LICENSES/`, in-product attribution), trademark register, user-facing legal documents (TOS, Privacy Policy, Cookie Policy, EULA, DPA, Sub-Processor List, Security Whitepaper, Accessibility Statement, AI Disclosure, Vulnerability Disclosure Policy, Imprint), versioning / notice / audit, and export controls / sanctions screening.

20. **Phase 19 — Brand & UI Consistency Across All Surfaces**
    Inventory every user-touching surface. Enforce a single brand-token system, logo system, typography, iconography, voice/tone/copy, motion/sound/haptics, and theme system (light/dark/HC). Produce a Surface × Brand-Element matrix and a token-source audit confirming zero hardcoded brand literals.

21. **Phase 20 — Cross-Surface Functional Parity**
    Produce a Feature × Surface parity matrix. Verify state synchronization (account, approvals, settings, traces), capability/permission parity, deep-link consistency, offline/degraded behavior, telemetry parity, and error/failure UI parity across all surfaces.

22. **Phase 21 — Cross-Surface Communications Distribution**
    Maintain a communications taxonomy and distribution matrix. Ensure single source of truth then fan-out, global read-state, deduplication, DnD respect, push payload hygiene, external channel adapters, status page integration, and localization.

23. **Phase 22 — Continuous Dogfooding Mode & Drift Detection**
    (Only in Continuous Dogfooding mode.) Run per-PR scoped audits and drift checks against baselines. Update baselines only on clean Pre-Launch Audit runs or release-manager promotion. Maintain living `AUDIT_LOG.md` with auto-escalation for aged findings.

## Output Deliverables

The final audit report is a single markdown file written to `audits/runs/<timestamp>/AUDIT_LOG_<LLM-NAME>_<YYYY_MM_DD>.md`. It MUST contain the following sections in this exact order, with clickable table-of-contents anchors:

### Standard Report Sections

1. **Executive Summary** — 3–5 bullets: what was audited, key conclusion, readiness verdict, and recommended action.
2. **Verification Results** — table: `| Check | Result | Notes |` listing every build, lint, test, and smoke command run during the audit.
3. **Coverage Snapshot** — table: `| Area | Status | Evidence |` summarizing which subsystems were reviewed and their maturity.
4. **Document Cross-Reference Matrix** — four-way reconciliation of `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `README.md`, and `CHANGELOG.md` with source code; every inconsistency flagged with location, severity, and proposed resolution.
5. **Finding Register** — a single markdown table with these exact columns:

   | Finding-ID | Name | Severity | Resolved? | Description |
   |---|---|---|---|---|
   | `AUDIT-FINDING-001` | gRPC Tasks lack durable model | HIGH | No | The Tasks service maps task ops onto agent messaging... |

   - **Finding-ID**: sequential `AUDIT-FINDING-NNN`
   - **Name**: concise human-readable title (max 60 chars)
   - **Severity**: `CRITICAL` | `HIGH` | `MEDIUM` | `LOW` | `INFO`
   - **Resolved?**: `Yes` | `No` | `Partial` | `N/A`
   - **Description**: the full explanation, location, and required fix

6. **Remediation Pass** — a single markdown table with these exact columns:

   | Finding | Status | Solution & Evidence |
   |---|---|---|
   | `AUDIT-FINDING-001` | Remediated | `CreateTask` now uses durable task records in `t3rnel-memory`... |

   - **Finding**: the Finding-ID
   - **Status**: `Remediated` | `In Progress` | `Deferred` | `Won't Fix` | `Blocked`
   - **Solution & Evidence**: what was done and where to verify it

7. **Remaining Items** — NEW. A bulleted or tabulated list of every finding that is **not** resolved, every deferred decision, and every open follow-up. Include: item, owner (agent role), priority, and proposed resolution date. This section is the go-to place for "what is still broken."

8. **Release Gate Recommendation** — a clear verdict: `APPROVED` (all gates green), `CONDITIONAL` (minor items remain, list them), or `BLOCKED` (critical/high findings remain, do not release). Include the rationale and the conditions for upgrading to `APPROVED`.

### Supplementary Deliverables (stored in per-run subdirectories)

9. Security audit findings (detailed, in `findings/security/`)
10. Compliance findings & Compliance Matrix (in `compliance/`)
11. Technical debt findings
12. Performance findings
13. Reliability findings
14. Dependency & supply chain audit findings + SBOM (in `sbom/`)
15. Cost / FinOps findings
16. Accessibility & i18n findings
17. Legal documents matrix, OSS attribution inventory, trademark register, copyright header audit
18. Surface × brand-element matrix and token-source audit
19. Feature × surface parity matrix and state-sync gap list
20. Communications distribution matrix and broadcast-point audit
21. Continuous-mode baselines and drift report (if applicable)
22. Architectural remediation plan with dependency order and risk tier per step
23. Full implementation corrections — complete files only, no truncation
24. Refactored package structures
25. Updated configuration files
26. Updated and added tests
27. Production deployment recommendations
28. `AUDIT_LOG.md` (the ambiguity/decision log, separate from the main report)
29. Remaining risks with owner and proposed resolution date
30. Final production readiness assessment with Definition of Done checklist

## Stop Condition

You stop exactly once: when all phases are complete, all exit criteria are met, and the final report is written to `audits/runs/<timestamp>/AUDIT_LOG_<LLM-NAME>_<YYYY_MM_DD>.md` with all standard sections present, clickable TOC, and every table populated.

**Boil the ocean. Then write the report. Then — and only then — stop.**
