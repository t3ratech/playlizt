<!-- doc-version: 1.0.0 | last-reviewed: 2026-05-19 | owner: architect -->

# T3rnel Document Generation Standards

> Universal standards for all documents, reports, logs, and artifacts produced by any T3rnel agent or workflow.

## Executive Summary

- **What:** A single source-of-truth for how T3rnel presents information to users and persists artifacts.
- **Why:** Inconsistent document formatting, random root-level file dumps, and missing ownership create friction, hide critical information, and make audits harder.
- **Key conclusion:** Every agent-generated document MUST follow these 15 rules; the architect enforces them during review.
- **Recommended action:** Pin this file in your agent context; reference it before producing any user-facing document.

## Table of Contents

- [1. Executive Summary First](#1-executive-summary-first)
- [2. Table of Contents](#2-table-of-contents)
- [3. Tables over Prose](#3-tables-over-prose)
- [4. Diagrams Where Helpful](#4-diagrams-where-helpful)
- [5. No Root-Level Log Files](#5-no-root-level-log-files)
- [6. Temporary Scripts in `scripts/tmp/`](#6-temporary-scripts-in-scriptstmp)
- [7. No Plain Text Dumps](#7-no-plain-text-dumps)
- [8. File Naming Convention](#8-file-naming-convention)
- [9. Document Versioning Header](#9-document-versioning-header)
- [10. No Binary Files in Repo Root](#10-no-binary-files-in-repo-root)
- [11. Generated Artifacts](#11-generated-artifacts)
- [12. Config Isolation](#12-config-isolation)
- [13. Data Files](#13-data-files)
- [14. Consistent Date Format](#14-consistent-date-format)
- [15. Every Document Has an Owner](#15-every-document-has-an-owner)
- [16. Audit Report Output Rules](#16-audit-report-output-rules)

## 1. Executive Summary First

Every user-facing document longer than 500 words MUST start with a concise executive summary (3–5 bullets):

| Bullet | Content |
|---|---|
| 1 | **What** — what this document is |
| 2 | **Why** — why it matters to the reader |
| 3 | **Conclusion** — the single most important takeaway |
| 4 | **Action** — what the reader should do next |
| 5 | *(optional)* **Scope** — what is and is not covered |

## 2. Table of Contents

Every document longer than one screen (approx. 40 lines) MUST have a clickable table of contents with Markdown anchor links to each H2/H3 section.

Example:

```markdown
## Table of Contents

- [1. Executive Summary First](#1-executive-summary-first)
- [2. Table of Contents](#2-table-of-contents)
```

## 3. Tables over Prose

Wherever data is naturally tabular — findings, comparisons, matrices, checklists, status summaries — use a Markdown table. Do **not** bury tabular data in paragraphs or bullet lists.

## 4. Diagrams Where Helpful

Architecture, data flow, state machines, and decision trees SHOULD include diagrams:

- **Preferred:** Mermaid (` ```mermaid `)
- **Fallback:** ASCII art or indented code blocks when Mermaid is unavailable

## 5. No Root-Level Log Files

All `.log`, `.jsonl`, `.txt`, and trace files go to `logs/` (or `logs/<subsystem>/`). The repository root is **never** a log dump.

| Type | Destination |
|---|---|
| Runtime logs | `logs/` |
| Subsystem logs | `logs/<subsystem>/` |
| Audit logs | `audits/runs/<timestamp>/` |
| CI logs | `.github/logs/` or `logs/ci/` |

## 6. Temporary Scripts in `scripts/tmp/`

Any one-off script, migration helper, or diagnostic tool created during an audit or fix session goes to `scripts/tmp/` with a dated prefix.

```
scripts/tmp/2026-05-19-fix-orphaned-tasks.py
scripts/tmp/2026-05-19-diagnostic-grep.sh
```

- **Lifespan:** 30 days max. After that, either promote to `scripts/` or delete.
- **Owner:** the agent that created it is responsible for cleanup.

## 7. No Plain Text Dumps

Never output unformatted lists of file paths, grep results, stack traces, or command output as raw text blocks in documents. Either:

- Wrap in fenced code blocks with a language tag, or
- Summarize into a Markdown table

## 8. File Naming Convention

| Category | Case | Example |
|---|---|---|
| Markdown docs | kebab-case | `security-policy.md` |
| Code / scripts | snake_case | `run_audit.py` |
| Config (YAML/TOML) | kebab-case | `otel-collector.yml` |
| Config (JSON keys) | snake_case | `"api_key_env"` |
| Dates in filenames | ISO 8601 short | `2026-05-19` |

## 9. Document Versioning Header

Every document has a version and last-reviewed date at the very top:

```markdown
<!-- doc-version: 1.2.0 | last-reviewed: 2026-05-19 | owner: architect -->
```

- **Version:** Semver `MAJOR.MINOR.PATCH`
  - `MAJOR` — structural change or owner change
  - `MINOR` — content addition or significant update
  - `PATCH` — typo fix, date bump, minor clarification
- **last-reviewed:** ISO 8601 short date
- **owner:** the agent role responsible for keeping it current

## 10. No Binary Files in Repo Root

Images, PDFs, archives, and other binary files go to dedicated asset directories:

| Type | Destination |
|---|---|
| Product images | `public/assets/` or `assets/` |
| Documentation images | `docs/assets/` |
| Build artifacts | `artifacts/` |
| Compiled WASM | `target/wasm32-unknown-unknown/` |

## 11. Generated Artifacts

Build outputs, generated clients, compiled WASM, and machine-generated code go to:

- `target/` — Rust build output
- `artifacts/` — release artifacts, VSIX, APK, etc.
- `gen/` — generated code (proto clients, OpenAPI stubs)

**Never commit generated artifacts** unless explicitly required by the build system.

## 12. Config Isolation

| Type | Destination |
|---|---|
| Runtime config | `config/` |
| Environment-specific overrides | `config/environments/` |
| Root-level config | Only for standard tooling (`.gitignore`, `Cargo.toml`, `package.json`) |

## 13. Data Files

| Type | Destination |
|---|---|
| Test fixtures | `tests/fixtures/` |
| Seed data | `data/seeds/` |
| Sample data | `data/samples/` |
| Audit evidence | `audits/runs/<timestamp>/` |

## 14. Consistent Date Format

| Context | Format | Example |
|---|---|---|
| Machine-readable / filenames | ISO 8601 | `2026-05-19T04:50:00Z` |
| Human-readable prose | Day Month Year | `19 May 2026` |
| Filename short form | ISO 8601 short | `2026-05-19` |
| Audit report filename | `YYYY_MM_DD` | `2026_05_19` |

## 15. Every Document Has an Owner

The `owner:` field in the version header names the agent role responsible for keeping the document current. Default owners by document type:

| Document Type | Default Owner |
|---|---|
| Architecture, ADR, process | `architect` |
| Security policy, incident response | `security-auditor` |
| API docs, runbooks | `doc-writer` |
| Release notes, changelog | `release-manager` |
| Test plans, coverage reports | `test-engineer` |
| Business docs, market analysis | `business-researcher` |

## 16. Audit Report Output Rules

All audit reports MUST follow this exact structure:

- **Directory:** `audits/runs/<ISO-8601-timestamp>/`
- **Filename:** `AUDIT_LOG_<LLM-FULL-NAME>_<YYYY_MM_DD>.md`
- **Example:** `AUDIT_LOG_KIMI_K2.6_2026_05_19.md`

The report MUST contain these standard sections in order:

1. **Executive Summary**
2. **Verification Results** (table: `| Check | Result | Notes |`)
3. **Coverage Snapshot** (table: `| Area | Status | Evidence |`)
4. **Document Cross-Reference Matrix**
5. **Finding Register** (table: `| Finding-ID | Name | Severity | Resolved? | Description |`)
6. **Remediation Pass** (table: `| Finding | Status | Solution & Evidence |`)
7. **Remaining Items** (unresolved findings with owner, priority, resolution date)
8. **Release Gate Recommendation** (`APPROVED` | `CONDITIONAL` | `BLOCKED`)

Per-run subdirectories also contain:
- `findings/` — individual finding detail files
- `remediation/` — patch files and evidence screenshots
- `sbom/` — SBOM artifacts
- `compliance/` — jurisdiction-specific compliance evidence

The legacy `AUDIT_LOG.md` in the repo root is a historical artifact. **Do not overwrite it.** New audits go into the dated run directory.
