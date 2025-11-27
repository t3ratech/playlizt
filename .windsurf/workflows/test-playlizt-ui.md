---
description: Unified Playlizt UI Testing Workflow with Strict Verification
auto_execution_mode: 3
---

# Playlizt Strict UI Testing Workflow

This workflow defines the rigorous process for validating the Playlizt platform's user interface. It combines automated Playwright testing with MANDATORY manual screenshot verification to ensure the system is not just "passing tests" but actually functioning correctly.

## Core Principles

1.  **Strict Assertions**: Tests must fail if text, elements, or URLs are not exactly as expected.
2.  **Screenshot Verification**: Every critical step generates a screenshot. These MUST be manually reviewed.
3.  **Fail Fast**: Stop at the first sign of failure. Do not ignore "minor" visual glitches.
4.  **Real Environment**: Tests run against the full Dockerized backend and Flutter web frontend.

## Prerequisites

- Backend services running: `./playlizt-docker.sh --status` (All UP)
- Flutter web app running on port 4090 (or configured port)
- `playlizt-ui-tests` module built and ready

## Workflow Steps

### 1. Environment Check

Before running any tests, verify the environment is healthy.

```bash
./playlizt-docker.sh --status
```

**Ensure Frontend is Running:**
If `curl -I http://localhost:4090` fails:
```bash
./playlizt-docker.sh --serve-web 4090
```

### 2. Execute Tests Sequentially

Run tests one class at a time to ensure isolation and focus.

#### A. Authentication Tests (Strict)

Validates Login, Registration, and Logout with strict text and URL checks.

```bash
./playlizt-docker.sh --tests "com.smatech.playlizt.ui.PlayliztAuthenticationTest" --module playlizt-ui-tests --test unit
```

**Verification:**
- Check terminal output for "✓ Screenshot..."
- **MANUALLY** open `src/test/output/auth/`
- Verify:
    - `01_login_load`: Playlizt logo/title visible?
    - `02_register_val`: Validation errors clearly shown?
    - `03_register_success`: Success state visible?
    - `04_login_val`: Error messages for invalid login?
    - `05_login_success`: Redirected to Dashboard? Elements visible?

#### B. Dashboard & Content Tests (Strict)

Validates Dashboard structure, Search, and Content interaction.

```bash
./playlizt-docker.sh --tests "com.smatech.playlizt.ui.PlayliztDashboardTest" --module playlizt-ui-tests --test unit
```

**Verification:**
- **MANUALLY** open `src/test/output/dashboard/`
- Verify:
    - `01_setup`: Dashboard loaded correctly?
    - `02_search`: Search results or "No results" message visible?
    - `03_content`: Content grid visible? Details page loaded?
    - `04_layout`: Footer/Header correct?

### 3. Manual Screenshot Audit (MANDATORY)

You must manually review the generated screenshots. Do not skip this step.

```bash
# List all screenshots
find playlizt-ui-tests/src/test/output -name "*.png" | sort

# Example: Open a specific folder (adjust for your OS)
xdg-open playlizt-ui-tests/src/test/output/auth/05_login_success
```

**Checklist per Screenshot:**
- [ ] **Text**: Is it readable? Is it the *correct* text?
- [ ] **Layout**: Are elements overlapping?
- [ ] **Images**: Did images load? (No broken image icons)
- [ ] **Errors**: Are there unexpected error banners?

### 4. Debugging & Fixing

If a test fails or a screenshot looks wrong:

1.  **Identify**: Is it a test bug (selector issue) or a real bug?
2.  **Fix**: Update code or test.
3.  **Rerun**: Run *only* the failing test method.
    ```bash
    ./playlizt-docker.sh --tests "com.smatech.playlizt.ui.PlayliztAuthenticationTest.test04_LoginValidation" --module playlizt-ui-tests --test unit
    ```
4.  **Verify**: Check the new screenshot.

## Success Criteria

The workflow is complete ONLY when:
1.  All strictly asserted tests pass.
2.  All screenshots have been manually reviewed and approved.
3.  No "silent failures" (tests passing but UI broken) exist.
