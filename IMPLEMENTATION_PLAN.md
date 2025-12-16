# Playlizt Implementation Plan

This document tracks the outstanding tasks and features to be implemented.
**Rule:** All new feature requests must be added here first, then marked as completed when done.

## 🚀 Outstanding Features

### Hybrid Offline/Online Refactor Framework (Framework Only)

- [x] Rename services and schemas to use `playlizt-` prefixes (e.g. `playlizt-api-gateway`, `playlizt-authentication`, `playlizt-content`, `playlizt-playback`).
- [x] Introduce `playlizt-content` multi-module parent with `playlizt-content-api` and `playlizt-content-processing` submodules, aligned with Groovy Gradle DSL.
- [x] Rename top-level environment variables to `PLAYLIZT_*` and propagate through `.env`, `docker-compose.yml`, `playlizt-docker.sh`, and Terraform.
- [x] Update Dockerfiles, `docker-compose.yml`, Terraform `services.tf`, and `playlizt-docker.sh` to use the new service and module names.
- [x] Update `ARCHITECTURE.md` and `README.md` to the new hybrid offline/online architecture (tabs, modules, naming, Groovy Gradle).
- [x] Run builds and all tests (unit + Playwright) after the framework changes and fix any failures caused by the refactor.

### Generic User Model (Remove Roles)

- [x] Replace the role-based model (USER/CREATOR/ADMIN) with a single generic authenticated user in `ARCHITECTURE.md` and `README.md`.
- [x] Update authentication and security configuration to remove `role` from JWT payloads and rely on basic authenticated vs anonymous checks only.
- [x] Update database schema and seed data to drop the `role` column from `users` and any creator/admin-specific constraints, while keeping ownership information for content.
- [x] Update the Flutter frontend (login/register, dashboards, analytics views) to remove role selection and make upload/stats features available to all authenticated users.
- [x] Update unit tests, integration tests and Playwright UI tests to reflect the generic user model with no roles.
- [x] Run the `/test-playlizt-ui` workflow and manually verify all screenshots after the role removal changes are in place.

### Global Naming & Packaging Standards

- [ ] Prefix every Java class, interface, enum, record, DTO, repository, controller, service, configuration and test type in the codebase with the `Playlizt` prefix (for example: `PlayliztUser`, `PlayliztAuthService`, `PlayliztContentController`, `PlayliztPlaybackRepository`).
- [ ] Change the base Java package from `com.smatech.playlizt` to `zw.co.t3ratech.playlizt` across all modules (main and test sources), build scripts and documentation.
- [ ] Update Playwright UI tests and Gradle includes to target the new package (e.g. `zw.co.t3ratech.playlizt.ui.*Test`) while preserving existing test semantics and screenshot structure.
- [ ] Ensure Spring Boot component scanning, JPA entity scanning and any reflection-based configuration are updated to the new base package so that no code paths rely on the old `com.smatech.playlizt` namespace.

### 1. Content Service (Port 4082)
- [x] **Content CRUD**: Full Create/Read/Update/Delete operations for video content.
- [x] **Category Management**: Admin/Creator APIs to manage content categories.
- [x] **Tag Management**: System for handling content tags.
- [x] **Advanced Search**: Full-text search with filters (Category, Tags, Duration).
- [x] **Gemini AI Integration**: Automated metadata enhancement (Description generation, Tag suggestion).
- [x] **Creator Upload Flow**: Robust upload handling (S3/Local storage optimization).

### 2. Playback Service (Port 4083)
- [x] **Session Management**: Tracking active viewing sessions.
- [x] **View Tracking**: Accurate view counting logic (e.g., 30s threshold).
- [x] **Watch History**: Storing and retrieving user watch history.
- [x] **"Continue Watching"**: Endpoint to return partially watched videos.
- [x] **Engagement Metrics**: Calculating completion rates, drop-off points.

### 3. AI Service (Port 4084)
- [x] **Recommendation Engine**: Personalized content feed based on history and tags.
- [x] **Metadata Enhancer Worker**: Async processing of new content.
- [x] **Watch Pattern Analysis**: Admin insights generation (Trending, Peak times).
- [x] **Sentiment Analysis**: Analyzed content metadata (Rating/Sentiment) via Gemini.
- [x] **Gemini API Fallback**: Handling API quotas/failures with fallback models.

### 4. API Gateway (Port 4080)
- [x] **Rate Limiting**: Implementing request limits per user/IP.
- [ ] **Advanced Routing**: Optimize routes for streaming data.
- [ ] **CORS Tuning**: Fine-grained CORS policies for web/mobile clients.

### 5. Frontend (Flutter)
- [x] **UI Rebranding**: Implement Black & White color scheme with Dark/Light mode support.
- [x] **Logo Integration**: Add TeraTech/Blaklizt logos and make them theme-aware.
- [x] **Video Player**: Full-featured video player (Play/Pause, Seek, Quality).
- [x] **Content Management Dashboard**: UI for uploading and managing content for any authenticated user.
- [x] **Reverse Video Order**: Display videos with Episode 1 at the top and Episode 5 at the end.
- [x] **YouTube Player Integration**: Implement video playback using `youtube_player_flutter`.
- [x] **Registration UI**: Registration screen for creating a generic authenticated user (no role selection).
- [x] **AI Recommendations UI**: "Recommended for You" section based on AI.
- [x] **Category Browsing**: Filter content by category chips.
- [x] **Sentiment Display**: Show AI rating and sentiment on content cards.

#### 5.1 Multimedia Shell UI – Tabs & Layout
- [ ] **Global Navigation Shell**: Replace the current single-page dashboard shell with a reusable root `Scaffold` that hosts a minimal top app bar (Playlizt/Blaklizt branding and a hamburger icon) and a tab-aware body.
  - Use a **single navigation rail** on the left that is present on all platforms; remove the bottom `BottomNavigationBar` entirely so there is only one tab bar.
  - The navigation rail exposes 6 fixed tabs in this exact order: **Library**, **Playlists**, **Streaming**, **Download**, **Convert**, **Devices**.
  - Each tab is backed by a dedicated root screen widget (e.g. `LibraryTabScreen`, `PlaylistsTabScreen`, etc.) with its own internal scroll / state, preserved when switching tabs.
  - All tab content must be **top-aligned** within its scrollable area; only the "Powered by Blaklizt Entertainment" footer strip in the Streaming tab is bottom-aligned.
  - The selected tab uses an oval/pill highlight that clearly surrounds but does not visually obscure the tab icon or label in either Light or Dark theme (fixing the light-mode overlap issue).
  - The T3Ratech logo is removed from the global header strip and instead rendered at the very top of the Settings drawer.
  - Interactive controls such as theme toggle, upload shortcut, analytics/dashboard entry point, profile details and logout are removed from the top app bar and surfaced as actions inside the Settings drawer.

- [ ] **Streaming Tab Migration**: Move all existing online/dashboard behaviours into the **Streaming** tab.
  - Relocate the content grid, search input, category chips, AI recommendation section, "Continue Watching" strip, and any online-only calls into the Streaming tab body.
  - Ensure the "Powered by Blaklizt" footer is rendered only within the Streaming tab’s scroll view, at the bottom of the content list.
  - When the backend is unavailable, the Streaming tab should fail fast with a clear error state (no silent fallbacks to local-only views inside this tab).

- [ ] **Tab State & Routing**: Persist which tab is currently selected and restore it on app restart.
  - Integrate with existing routing/navigation (e.g. named routes or `onGenerateRoute`) so that direct deep links such as `/#/streaming` or `/#/download` open the correct tab.
  - Ensure video playback screens can be launched from any tab while keeping the shell navigation consistent when popping back.

#### 5.2 Library Tab – Local Media Shell (Phase 1: UI)
- [ ] **Library Landing UI**: Implement a Library tab landing view focused on local files (offline-first).
  - Show a summary header section (e.g. "Local Library") with quick stats for total items and last scan time.
  - Provide primary actions: **Scan Folders**, **Rescan Now**, and **Open Folder**.

- [ ] **Folder/Item Browser (Read-Only Phase)**:
  - Render a 2–3 column grid/list of media items inspired by desktop players (e.g. artists/albums/tracks), but initially backed by a basic filesystem listing from configured scan folders.
  - Support simple sort toggles (by Name, Date Added) and a text search box scoped to local items.
  - Tapping an item routes into the existing playback flow with a `file://` media source, distinct from streaming URLs.

- [ ] **Library Indexing Contract (Design Only)**:
  - Define a local `LibraryItem` model (ID, path, display title, duration, media type, hash) with clear separation from backend `Content` DTOs.
  - Decide where lightweight indexing metadata is stored (e.g. local SQLite/Isar file) without yet implementing full indexing logic.
  - Document that subsequent phases will implement actual background scanning and incremental updates based on this contract.

#### 5.3 Playlists Tab – Unified Local/Online Lists (Phase 1: UI)
- [ ] **Playlists Landing UI**:
  - Display a list of playlists showing name, number of items, and whether the playlist is **Local**, **Online**, or **Hybrid**.
  - Add actions to **Create Playlist**, **Rename**, **Delete**, and **Duplicate** playlists.

- [ ] **Playlist Editor Shell (UI)**:
  - Implement a playlist editor screen where users can see the ordered list of items and re-order via drag-and-drop.
  - Items can reference either local `LibraryItem` entries or online `Content` entries; the UI should visually distinguish these (e.g. icon or chip), even if hybrid resolution is implemented later.

#### 5.4 Download Tab – Download Manager UI (Phase 1: Full Behaviour)
- [ ] **Download Input Row**:
  - At the top of the Download tab, render a single-line URL input box and a `Download` button aligned horizontally (desktop) or stacked with responsive layout (mobile).
  - The input accepts any HTTP/HTTPS media URL (initially focusing on direct file URLs; YouTube-style extraction will be layered on later).
  - Disable the `Download` button while the URL is empty or clearly invalid according to a strict URL pattern.

- [ ] **Default vs Custom Location Switch**:
  - Add a primary switch 
    - **"Use default download location"** (ON by default).
  - When ON:
    - Show a collapsed row (advanced section) revealing the **current default folder path** (initial default `~/Downloads`) in a read-only label.
    - Provide a **"Change"** button that opens a folder picker dialog, and a hidden/advanced editable textbox to override the path manually when the user chooses "Edit path".
  - When OFF:
    - Hide the default path editor and configure the next `Download` action to immediately open a **Save As** dialog where the user can select file name and target folder.
  - The default location and any user override are persisted in the local settings store and honoured across restarts.
  - When the default folder is updated from the Settings drawer (see **5.7 Global Settings & Hamburger Menu**), both the Download tab UI and the `DownloadManager` service must immediately honour the new value without requiring an app restart.

- [ ] **Download Queue & Progress Panel**:
  - Implement a scrollable panel below the input row to list **all current and recent downloads**.
  - Each download row shows: filename, source URL host, target directory, current status (Queued, Downloading, Paused, Completed, Failed, Cancelled), and a progress bar with percentage and speed when available.
  - Provide per-item controls: **Pause/Resume**, **Cancel**, and **Open Folder** (for completed items only).
  - Ensure state is resilient to app restarts by persisting in-progress and completed download metadata locally and resuming or clearly failing in-progress items on next launch.

- [ ] **Download Engine Abstraction (Local Only, No Backend Dependency)**:
  - Implement a `DownloadManager` service in Flutter that handles multiple concurrent HTTP downloads using a configurable maximum concurrency and supports pause/resume where protocol allows, otherwise cancel/restart semantics.
  - Expose a stream-based API so the UI can subscribe to download state updates and update the progress panel in real time.
  - Enforce strict error handling and surface clear error messages in the UI (e.g. network errors, disk full, permission denied) rather than silently swallowing failures.

#### 5.5 Convert Tab – Conversion Shell (Phase 1: UI)
- [ ] **Convert Landing UI**:
  - Provide a simple UI to pick one or more existing Library items and a target output profile (e.g. MP3, MP4 720p, Audio-only, Clip segment).
  - Expose fields for start/end timestamps (HH:MM:SS) for clipping scenarios.
  - For this phase, do not wire to a real transcoder yet, but finalise the UI contract and model objects (`ConversionJob`) to be used by a future ffmpeg-backed worker.

- [ ] **Conversion Queue Panel (Design)**:
  - Mirror the visual style of the Download queue panel for conversion jobs (Pending, Running, Completed, Failed, Cancelled), with progress indicator and per-item controls.

#### 5.6 Devices Tab – Extensibility Shell (Phase 1: UI)
- [ ] **Devices Landing UI**:
  - Show a placeholder list for potential sync/cast targets (e.g. "This Device", "Living Room TV", "Bluetooth Speaker"), with clear indication that advanced device integration is a future feature.
  - Define a `PlaybackDevice` abstraction (ID, name, type, capabilities) to be used later when real device discovery is implemented.

#### 5.7 Global Settings & Hamburger Menu
- [ ] **Hamburger Menu Entry Point**:
  - Add a three-line hamburger icon to the minimal top app bar that opens a side drawer or full-screen settings page.
  - The hamburger is the single entry point into Settings; the top app bar no longer exposes theme, upload, analytics or profile controls directly.

- [ ] **Settings Structure**:
  - **General**: default start-up tab, language/locale (if applicable), behaviour when backend is unreachable, and per-user **tab visibility** configuration.
    - When running on Flutter Web, the Library and Devices tabs cannot be enabled; Streaming must always be visible and acts as the default start-up tab.
    - Whenever the visible tab set changes, the saved start-up tab must be updated to a still-visible tab (falling back to Streaming if necessary).
  - **Library**: list of **scan folders** with add/remove controls, recursive scan toggle, and a button to trigger a manual rescan.
  - **Download**: default download location editor (synchronised with the Download tab switch), maximum concurrent downloads, and whether to auto-import successful downloads into the Library. Even when **"Use default download location"** is ON, the user can open a native folder chooser dialog from Settings to change the default folder.
  - **Appearance**: default theme (Light/Dark/System), accent colour choice, and options for compact vs spacious layout. The **default theme for new users and anonymous sessions is Dark mode**.
  - **Playback**: default playback speed, enable/disable "Continue Watching" for local items, and whether to remember per-item positions.
  - **Account & Actions**: cluster global actions such as upload content, analytics/dashboard entry point, profile details and logout into dedicated tiles inside Settings.

- [ ] **Settings Persistence**:
  - Implement a central settings store (e.g. using Flutter `shared_preferences` or an equivalent persistent storage mechanism) that reads from and writes to real configuration values (no hardcoded defaults beyond initial bootstrap values defined in config).
  - Ensure settings changes take effect immediately where possible, and are reliably restored on next app start.

### 6. Security & Authentication
- [x] **User Registration**: Simple registration flow for a generic authenticated user (no roles).
- [x] **Flexible Login**: Support login via Username or Email.
- [x] **Strong Hashing**: Enforce Argon2id for password storage.
- [x] **UX Improvements**: Enter key submission and clear validation.
- [ ] **MFA**: Multi-Factor Authentication (Future).
- [x] **Analytics Dashboard**: Insights for usage and engagement.
- [x] **Profile Management**: User profile editing and settings.
- [x] **"Continue Watching" UI**: Horizontal list of unfinished videos.
- [ ] **Optional Login & Anonymous Mode**: Add a "Continue without login" path on the login screen that starts an anonymous session. Anonymous users may browse public catalogue data and use purely local features (e.g. Library, Playlists, Download playback) but are blocked from any operation that requires database access such as uploading content, editing profiles or viewing personalised analytics.
- [ ] **Per-User Settings Handshake**: On successful login, load or create a `PlayliztUserSettings` record and return the user's effective settings (theme, startup tab, visible tabs, download directory, library scan folders, max concurrent downloads, etc.) to the frontend so that `SettingsProvider` initialises from server-side values. When no user is logged in, the app falls back to environment-driven defaults defined in configuration files rather than hardcoded constants in code.

### 6. Infrastructure & Testing
- [x] **GCP Infrastructure**: Terraform configuration for Cloud Run & Cloud SQL.
- [x] **Integration Tests**: Testcontainers-based integration tests for all services.
- [x] **End-to-End Tests**: Full flow testing (Frontend -> Gateway -> Service -> DB).
- [x] **Log Management**: Centralized logging setup.
- [ ] **Production Hardening**: Security headers, Https, etc.
 - [x] **UI Testing Updates**: Stabilized Playwright UI tests (Flutter Web Semantics hydration + safer load waiting) and ensured the full UI test suite passes again.
 - [ ] **File Header Template Rollout**: Apply the Windsurf file header template to all applicable source files (Java, Dart, shell scripts, etc.) using the per-file creation timestamp (format `YYYY/MM/DD HH:MM`) obtained via shell commands for each file.

---

## ✅ Recently Completed
- [x] **Database Migration**: Switched from Flyway to Hibernate Auto-DDL (`create`).
- [x] **Data Seeding**: Implemented `import.sql` for initial user (`tkaviya`) and content (Tha Streetz TV).
- [x] **Auth Service**: User registration and Login (JWT) for a single generic authenticated user (no roles).
- [x] **Basic Dashboard**: Home screen with content grid and search.
- [x] **AI Recommendations & UI Tests**: Implemented "Recommended for You" UI, category chips and sentiment labels, plus stabilized Playwright flows (authentication, dashboard, recommendations, and video playback with crash-safe navigation).
 - [x] **UI Test Harness Hardening**: Enabled Flutter Semantics at startup and added Semantics labels to critical headings so Playwright can reliably detect UI elements.
 - [x] **UI Alignment Tweaks**: Streaming tab content top-aligned (footer excluded) and T3raTech logo centered in the Settings drawer.
