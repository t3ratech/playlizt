---
description: Playlizt UI screenshot verification and cleanup
---

# Playlizt UI Screenshot Verification & Cleanup Workflow

This workflow ensures every Playlizt UI test screenshot is relevant, correctly named, and visually matches the expected UI state.

## 1. Preparation

1. **Ensure tests are green**
   - Run full UI + backend test suite:
     - `./playlizt-docker.sh --test-all --module playlizt-ui-tests`
     - `./playlizt-docker.sh --test-all`
   - Confirm both commands finish with `All tests passed!`.

2. **Identify screenshot root**
   - All Playwright screenshots must live under:
     - `playlizt-ui-tests/src/test/output`

## 2. Enumerate all screenshots

1. **List all PNG screenshots**
   - From the project root, list images:
     - `find playlizt-ui-tests/src/test/output -type f -name "*.png" | sort`
   - Treat this list as the authoritative set of screenshots to audit.

2. **Group by scenario**
   - Conceptually group screenshots by their directory structure:
     - `category` (e.g., `authentication`, `recommendations`, `admin`)
     - `test-name` (e.g., `01_invalid_login`, `01_fresh`)
     - `step` (e.g., `01_dashboard.png`, `02_after_login.png`)

## 3. Map screenshots to tests

For each screenshot **one by one**:

1. **Derive identifiers**
   - From the relative path `playlizt-ui-tests/src/test/output/<category>/<test>/<step>.png` extract:
     - `category`
     - `test`
     - `step` (filename without extension)

2. **Locate generating test code**
   - Search in `playlizt-ui-tests/src/test/java` for the step name or folder name:
     - Look for `takeScreenshot("<category>", "<test>", "<step>")` calls (or similar helpers).
   - Identify:
     - The test class (e.g., `PlayliztAuthenticationTest`)
     - The JUnit test method (e.g., `test01_InvalidLoginShowsError`)

3. **Determine expected UI state**
   - Read the test method and surrounding comments/assertions to understand what should be on screen when the screenshot is taken.
   - Examples:
     - Invalid login: login screen with error banner.
     - Successful login: dashboard with user logged in.
     - Recommendations: "Recommended for You" visible with relevant tiles.

## 4. Manually inspect each screenshot

For each screenshot (still one by one):

1. **Open the image**
   - Use the IDE/image viewer to open the PNG.

2. **Compare against expectations**
   - Check that:
     - The high-level screen matches the test (e.g., login vs dashboard vs admin analytics).
     - Critical UI elements required by the test are visible (e.g., error message, recommendations header, admin analytics link).
     - There are no obvious rendering or navigation errors (blank screens, wrong route, etc.).

3. **Classify the screenshot**
   - **Obsolete**: no corresponding `takeScreenshot(...)` call or test scenario anymore.
   - **Incorrect**: there is a test, but the screenshot does not show what the test describes.
   - **Correct**: matches the current test logic and expectations.

## 5. Handle obsolete screenshots

For each screenshot classified as **Obsolete**:

1. **Double-check usage**
   - Search for the path components (category/test/step) in `playlizt-ui-tests/src/test/java`.
   - If no matches and no active test refers to that screenshot, treat it as obsolete.

2. **Delete the file**
   - Remove the PNG via a terminal command so the deletion is visible in git:
     - `rm playlizt-ui-tests/src/test/output/<category>/<test>/<step>.png`

3. **Verify cleanup**
   - Re-run `find ... -name "*.png"` and ensure the deleted file no longer appears.

## 6. Fix incorrect screenshots (treat as test failures)

For each screenshot classified as **Incorrect**:

1. **Treat the underlying test as failing**
   - Even if JUnit reports it as passing, consider the scenario broken until the screenshot matches expectations.

2. **Investigate the cause**
   - Inspect the test method:
     - Are we taking the screenshot at the wrong step?
     - Is the navigation or login flow incomplete?
     - Are we ignoring an error condition that should be asserted?
   - Check related helpers in `BasePlayliztTest` and the corresponding Flutter screen.

3. **Adjust the test or helper**
   - Fix navigation (e.g., wait for Flutter ready, ensure correct route).
   - Strengthen or correct locators and waits.
   - Move or rename the `takeScreenshot(...)` call so it captures the correct state.
   - Do **not** relax assertions just to make the screenshot pass; align screenshots with real expected behaviour.

4. **Regenerate screenshots**
   - Run the specific test class (or method) that owns the screenshot via `playlizt-docker.sh` with `--module playlizt-ui-tests` and a `--tests` filter.
   - Confirm the test passes and generates a new screenshot.

5. **Re-verify the new image**
   - Open the regenerated PNG.
   - Confirm it now matches the expected UI state.

## 7. Final consistency pass

1. **Re-run all UI tests**
   - `./playlizt-docker.sh --test-all --module playlizt-ui-tests`
   - Ensure all tests and screenshot generations pass.

2. **Optional: run full test suite**
   - `./playlizt-docker.sh --test-all`

3. **Confirm screenshot directory is clean**
   - Re-list all screenshots and spot-check a few per category.

This workflow must be executed in full whenever UI flows change significantly or when screenshot discrepancies are discovered.
