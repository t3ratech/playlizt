---
description: Iterative Patrol Download Fixes Workflow
---

This workflow iterates through locally configured download-test URLs, running the Patrol integration test and fixing extractors/download headers until each URL passes end-to-end (download + file size + playback).

## Preconditions
- You have created/updated the gitignored URL file:
  - `playlizt-frontend/playlizt_app/integration_test/.download_test_urls.local.txt`
- Only **one** URL line is uncommented at a time while iterating.
- The test is executed on the Linux desktop device.

## Rules
- Do **not** commit the local URL file (it is gitignored).
- Do **not** add defaults/placeholders in code; fail fast if config is missing.
- When adding a *new extractor for a new site*, append **one additional random real URL** for that site to the local URL file.
- Do **not** stop the process for any reason. If a URL appears broken/unreachable, quarantine it and continue to the next URL.

## Steps

1) Run the Patrol download integration test for the currently-uncommented URL
- From `playlizt-frontend/playlizt_app`:
  - `flutter test integration_test/patrol_download_test.dart --timeout=none -d linux`

2) If the test fails, fix the root cause
- Identify whether failure is:
  - extraction failure (no formats / wrong URL)
  - download failure (HTTP 403/404/HTML file) due to missing headers/cookies
  - stall/progress failure
  - playback initialization failure
- Apply the smallest change consistent with existing architecture:
  - Prefer: improve site-specific extractor OR improve `GenericIE` extraction and per-format `httpHeaders`.
  - Ensure `MediaFormat.httpHeaders` includes at minimum:
    - `User-Agent`
    - `Referer` (page URL)
    - any required cookies from `Set-Cookie` or HTML gating cookies

2a) If you are unsure whether an error is caused by our code or by the site, validate with curl
- Use curl to reproduce the HTTP status/content-type outside the app.
- Use a browser-like user agent and include the page URL as `Referer` when relevant.
- If curl reproduces the same failure (e.g. persistent 403/451/503, HTML returned instead of media), treat the URL as temporarily broken.
- Quarantine the URL by commenting it out in `integration_test/.download_test_urls.local.txt`, then continue to the next URL (do not stop the iteration).

3) Re-run the Patrol test until the single URL passes
- Repeat Step (1) until it passes end-to-end.

4) Uncomment the next URL and repeat
- In `integration_test/.download_test_urls.local.txt` uncomment exactly one additional URL.
- Repeat Steps (1)-(3).

5) When adding a new extractor for a new site: add a random real URL for that site
- Fetch the homepage HTML and pick one likely video/watch link.
- Example approach (conceptual):
  - `curl -fsSL "https://<site-host>/"` and parse out a candidate watch URL.
- Append that URL (as a new uncommented line) to `integration_test/.download_test_urls.local.txt`.

6) After all URLs pass
- Run the broader frontend test suite per repo conventions.
- Prepare a combined commit+push command.
