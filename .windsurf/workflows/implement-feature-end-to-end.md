---
description: End-to-end Streetz feature implementation from SYSTEM-DESIGN.md section with builds, health checks, curl + Playwright + unit tests, and docs updates
auto_execution_mode: 3
---

# Implement a Feature End-to-End (No Prompts, Fully Automated, Commit gated)

This workflow implements any selected feature described in `SYSTEM-DESIGN.md` from spec to production-like verification. It performs coding, builds, container orchestration, health checks, API/UI/Telegram wiring, unit/integration tests, curl tests, and Playwright tests. As the name of the workflow says, this should completely implement what is required from the beginning to the very end and make sure it is tested and working and production ready with no placeholder code, no defaults, no todos, no failsaifs, ***NO UNIMPLEMENTED CODE WHATSOVER!!! IMPLEMENT EVERYTHING FROM END TO END INCLUDING SUBTASKS AND FUNCTIONS AND MODULES AND CONFIGS***. The functionality should be complete, testable, and production ready and documented. Afterwards, do not run any GIT process, wait for explicit request before doing anything GIT related. The major rule about this workflow is to understand the existing system starting with existing architecture and patterns, followed by `SYSTEM-DESIGN.md`, checking with streetz/AOW_System_Design.md when unsure, and lastly checking with the user, then implement the requirements of the system without repeated user updates, user confirmations, interruptions and most importantly do no seek user approvals. I made this workflow so I can start it and walk away and do something else and return when everything is working. I would rather make corrections than constantly being asked for approval. I want this done END TO END before ever talking to you. DO NOT TALK TO THE USER EVER UNLESS IT IS A MAJOR STRCTURAL DECISION. Assume the user is not available and when he comes back, the system must work according to the requirements, and even if it works badly or works in an undesired way for the user, WORKING is the most important result, than the method, so make sure it is WORKING END TO END, with all tests passing and all requirements fulfilled, rather than focusing on getting tht details right.
1
Note: Use only real configuration values in environment and properties. No placeholders. If a value is missing, allow the system to fail fast for correct configuration alignment (see `SYSTEM-DESIGN.md` section 15).

## Inputs you provide once at start
- Feature section text from `SYSTEM-DESIGN.md` (copy/paste).
- Target modules impacted (e.g., `streetz-api`, `streetz-web`, `streetz-telegram`, `streetz-common-*`).

## High-level steps
1. Parse the plan section and derive feature scope, acceptance criteria, and impacted modules.
2. Verify environment and services, then implement across modules:
   - API (controllers/services/DTOs)
   - Web (SPA wiring, UI updates, config)
   - Telegram (commands to API, i18n messages)
   - Shared (DTOs/exceptions)
4. Add automated tests:
   - Unit and slice tests (JUnit) for API/service logic
   - cURL integration checks against running services
   - Playwright UI tests for web SPA flows
5. Rebuild and restart services with health validation after each stage.
6. Update docs: `SYSTEM-DESIGN.md` and relevant READMEs.
7.Do NOT initiate anything GIT related

---

## Steps

1) Understand and scope the feature
- Extract feature title, user stories, acceptance criteria from the provided `SYSTEM-DESIGN.md` section.
- Identify impacted modules and data contracts (DTOs) per `SYSTEM-DESIGN.md` standards.
- Define message keys for all user-facing strings (no hardcoded strings).

2) Ensure stack is clean and healthy
- Destroy-or-restart only if needed. Prefer rebuild/restart with health validation.
// turbo
- Run:
  - `./streetz-docker.sh --status`
  - If not healthy, `./streetz-docker.sh -rrr streetz-database streetz-api streetz-web streetz-telegram`

3) Implement shared contracts (if needed)
- Edit `streetz-common/streetz-common-shared/` to add/update DTOs, enums, error shapes.
- Follow package conventions in `com.t3ratech.streetz.common.shared.dto`.
- Add tests in `streetz-common-shared` for DTO mappers or utility logic.

4) Implement API backend
- In `streetz-api`:
  - Add/extend service interfaces and implementations.
  - Add controller endpoints under `http://localhost:${API_INTERNAL_PORT}/api/...` (see `SYSTEM-DESIGN.md` section 15.8).
  - Ensure CORS is compatible (allowed origins via `API_ALLOWED_ORIGINS`).
  - i18n: return message keys or formatted messages consistently.
- Tests:
  - Add JUnit tests under `streetz-api/src/test/java/...` for services and controllers (WebMvcTest/MockMvc where applicable).
  - Ensure tests do not rely on defaults; use explicit config or mocks.

5) Wire Web SPA (if applicable)
- In `streetz-web`:
  - Update `static/js/app.js` for any new private commands, menus, or UI endpoints.
  - Ensure `/ui/config` provides any new required runtime config (fail-fast if missing).
  - Add targeted UI pieces in `static/app.html` + minimal CSS.
- Tests:
  - Add Playwright tests in `streetz-web/tests/` covering the new flow (registration/login if needed, navigation, command send, state assertions).
  - Install Playwright once per repo (if not present): `npm init -y && npm i -D @playwright/test && npx playwright install --with-deps`.

6) Wire Telegram (if applicable)
- In `streetz-telegram`:
  - Update `TelegramBotService` to parse and route any new commands to `StreetzApiClient`.
  - Ensure `TelegramProperties` has correct keys set in env/properties:
    - `streetz.telegram.bot.token`
    - `streetz.telegram.bot.username`
    - `streetz.telegram.bot.api-base-url` (must include `/api` and use hyphen, not underscore)
  - Add i18n message keys in `langs.messages` bundles.
- Tests:
  - Unit test command parsing and API client integration (mocked) where feasible.

7) Build and run module tests locally
// turbo
- Run:
  - `./gradlew clean test` (root) — Java unit tests across modules

8) Rebuild and restart affected services with health validation
// turbo
- Run (adjust list to affected modules):
  - `./streetz-docker.sh -rrr streetz-api`
  - `./streetz-docker.sh -rrr streetz-web`
  - `./streetz-docker.sh -rrr streetz-telegram`
- Verify:
  - `./streetz-docker.sh --status` (all healthy)

8a) Start test environment and run comprehensive multi-language tests
// turbo
- Start test environment:
  - `./streetz-docker.sh --test-env start`
- Verify test environment health:
  - `./streetz-docker.sh --test-env status`
- Run multi-language test suite:
  - `./streetz-docker.sh --test-multi-lang unit` — Unit tests in all languages
  - `./streetz-docker.sh --test-multi-lang integration` — API integration tests in all languages
  - `./streetz-docker.sh --test-multi-lang ui` — Playwright UI tests in all languages
- Stop test environment when done:
  - `./streetz-docker.sh --test-env stop`

9) cURL end-to-end verification (API + session)
// turbo
- Run (sample flow, adapt per feature):
  - Verify web endpoints:
    - `curl -sf -o /dev/null -w "%{http_code}\n" http://localhost:7080/` → 200
  - Register unique user:
    - `USER="user$(date +%s)"; EMAIL="$USER@streetz.local"; PASS="Reg1!$RANDOM"`
    - `curl -s -i -H 'Content-Type: application/json' -d "{\"username\":\"$USER\",\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" http://localhost:7081/api/v1/auth/register`
  - Login and capture cookie:
    - `curl -s -i -c /tmp/streetz_cookies.txt -H 'Content-Type: application/json' -d "{\"username\":\"$USER\",\"password\":\"$PASS\"}" http://localhost:7081/api/v1/auth/login`
  - Exercise new API endpoints with `-b /tmp/streetz_cookies.txt` and assert JSON conditions with `jq` where appropriate.

10) Playwright UI tests
- Pre-req (once):
  - `npm init -y` (in `streetz-web` or repo root you choose to host tests)
  - `npm i -D @playwright/test` and `npx playwright install --with-deps`
- Create tests under `streetz-web/tests/`:
  - Include flows for login/registration and the new feature scenarios.
- Execute:
  - `npx playwright test --reporter=list` (or `html`)

11) Documentation updates
- Update `SYSTEM-DESIGN.md` to reflect any new modules, endpoints, message keys, or config requirements.
- Update `README.md` or module-level READMEs with usage details and run commands.

12) Validation (optional)
// turbo
- Run:
  - `./streetz-docker.sh --status`
  - Re-run a subset of cURL and Playwright tests to validate after rebase/merge.

---

## Notes & Constraints
- Never use placeholder values, default values, or placeholder implementation (rather implement it end to end). If config is missing, let the service fail fast.
- Add JPA/persistence to `streetz-telegram` as required.
- For `streetz-web`, all runtime values must come from `/ui/config` with env-backed values; missing envs must fail.
- Respect `docker-compose.yml` environment and healthcheck design; use internal ports inside containers.
- Do not do anything GIT related or even offer or propose it, only the user must initiate anything to do with GIT.