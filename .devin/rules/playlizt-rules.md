---
trigger: always_on
---

# Playlizt Development Rules

## Commands and Tool Usage
- **CRITICAL**: ALWAYS use IDE-visible tools (edit, write_to_file, run_command) instead of MCP tools (mcp1_Edit, mcp1_Write, mcp1_Bash)
- Run every required command exactly as documented. Never pipe through `tail`, `>&`, or similar filters that hide output; full logs are mandatory for diagnosis and user visibility.
- Never redirect stderr to /dev/null or hide any output - the user must see everything.
- All terminal operations must use `run_command` so they appear in the IDE terminal.
- All file edits must use `edit` or `write_to_file` so they appear in the IDE.
- No hidden background operations - everything must be visible to the user.
- You must usee the IDE for all terminal and editing so the user has visibility, do not use obscure MCP tools

## Golden References
1. `ARCHITECTURE.md` (authoritative technical guide)
2. Existing module implementations in this repository
3. Ask the user when anything remains unclear after consulting the documentation

## Coding Rules
- Absolutely no hardcoded defaults, placeholders, TODO/FIXME markers, or fallbacks. The system must fail fast when configuration is missing or invalid.
- Reuse existing functionality; change as little as possible and stay within the documented architecture.
- Never introduce new technologies, refactor broadly, or alter architecture without explicit user approval.
- Understand the problem via logs and documentation before modifying code. Address root causes rather than symptoms.
- Implement production-ready solutions end to end with appropriate automated tests.
- Use Lombok everywhere possible for all entity, DTO, and service classes.

## Configuration Standards
- Configuration hierarchy: `.env` → `docker-compose.yml` → Dockerfile build args/env → `application-{profile}.properties` → runtime stores (databases, secrets managers).
- All environment-specific values live in `.env`. Docker Compose passes them as build args/env vars. Dockerfiles consume only the passed args. Spring configuration resolves strictly from external properties.
- Never define defaults in code or properties. If a value is missing, the application must fail to start.

## Testing Requirements
- Every change requires automated tests where behaviour changes (unit, integration, or end-to-end as applicable).
- Prefer targeted Gradle tasks via `playlizt-docker.sh --test …`. Document test execution and outcomes.
- Validate logs for absence of errors and correct configuration loading when investigating issues.
- Maintain minimum 80% test coverage across all services.

### UI Testing (Playwright)
- **CRITICAL**: Manual screenshot verification is MANDATORY for all UI tests.
- Every UI test must capture screenshots at key interaction points.
- Screenshots MUST be manually opened and visually inspected before considering tests complete.
- Flutter web uses canvas rendering - standard DOM selectors (locator, getByText) will NOT work.
- Use screenshot-based verification as primary test validation method.
- For Flutter interactions, use `page.evaluate()` with JavaScript instead of standard selectors.
- Focus assertions on page URLs, titles, and JavaScript state rather than DOM elements.
- Test in NON-HEADLESS mode to enable visual verification during test runs.
- Document all visual verification results in SCREENSHOT_VERIFICATION_COMPLETE.md.
- Screenshot organization: `output/{category}/{test-name}/{step}-{action}-{state}.png`
- Quality requirements: Readable text, proper alignment, correct data display, no rendering errors.
- Issue classification: Naming Problem, Test Bug, Code Bug, Strict Testing Gap.
- Fix workflow: Identify issue → Fix code → Rerun SPECIFIC test → Verify screenshot → Document fix.

## Build & Operations Rules
- All container lifecycle work goes through `playlizt-docker.sh`. Never call `docker`, `docker-compose`, or Gradle directly.
- "Rebuild and fix" means destroy everything for the affected service, rebuild one service at a time in dependency order, verify health checks, inspect mounted logs, and confirm configuration before progressing.
- Improve automation by enhancing `playlizt-docker.sh`; do not add parallel helper scripts.
- Always run builds in detached mode when required by the script flags.
- JAR files must be named after their service (e.g., `auth-service.jar`, not `app.jar`).

## Execution Discipline
- Follow the requested process precisely. If a process fails, stop and ask for guidance rather than improvising alternative approaches.
- Use only real values—no samples or placeholders in code, documentation, or configuration.
- Never perform Git operations without explicit instruction and approval of the combined command sequence.

## Documentation
- Update `ARCHITECTURE.md`, README files, and workflows whenever behaviour, configuration, or processes change.
- Keep documentation descriptive of the current state; do not include future plans or historical commentary.
- **STRICT RULE**: The system must ONLY contain 3 Markdown files:
    1. `ARCHITECTURE.md` (Technical guide)
    2. `README.md` (User guide & Setup)
    3. `IMPLEMENTATION_PLAN.md` (Outstanding tasks & features)
- **NEVER** create any other `.md` files in this system.
- **Process**: Every feature request or change must be inserted into `IMPLEMENTATION_PLAN.md` FIRST, then ticked off as completed.


## Success Criteria
- Code matches documented architecture in `ARCHITECTURE.md`.
- Configuration is externalised with no defaults.
- Tests cover new logic and pass via `playlizt-docker.sh`.
- Docker workflows operate exclusively through `playlizt-docker.sh` with validated health checks and logs.
- Documentation remains accurate and complete after changes.
- All classes use Lombok where applicable.
- PostgreSQL 17 used for production, Testcontainers for tests.
- Argon2id used for password hashing.
- Gemini API integrated with model `gemini-2.0-flash-exp`.
- All Dockerfiles use `eclipse-temurin:25-jre-jammy` (or better if exists).

## Failure Modes to Avoid
- Direct Docker/Gradle commands, bypassing `playlizt-docker.sh`.
- Introducing defaults or placeholders to bypass missing config.
- Commenting out failing tests instead of fixing the root cause.
- Creating ad-hoc scripts or documentation outside the established structure.
- Deviating from `ARCHITECTURE.md` without approval.
- Using generic JAR names like `app.jar` instead of service-specific names.
- Not using Lombok for boilerplate code.
- Hardcoding configuration values.