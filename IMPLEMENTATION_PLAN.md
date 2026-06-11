# Playlizt Implementation Plan

This document tracks the outstanding tasks and features to be implemented.
**Rule:** All new feature requests must be added here first, then marked as completed when done.

## 🚀 Outstanding Features

### Full Downloader, Converter And Playback Engine Expansion

- [ ] **Downloader Inventory Port/Integration: 1,273 Extractors**
  - Port/integrate every downloader extractor from the configured extractor catalog so Playlizt can identify and extract all 1,273 supported site entries through Playlizt-owned models.
  - Each extractor result must normalise into Playlizt metadata: title, description, duration, uploader/channel, upload date, webpage URL, thumbnails, subtitles, formats, chapters, playlist entries and warnings.
  - Add automated inventory verification that fails when the implemented extractor count is lower than 1,273 or when any extractor cannot be loaded.

- [ ] **Downloader User Experience And Progress**
  - Replace raw command/process output with Playlizt progress events and friendly messages for extracting, awaiting user input, queued, downloading, post-processing, completed, failed, cancelled and retriable states.
  - Add per-item progress bars with percent, downloaded bytes, total bytes, speed, ETA, active fragment count and current post-processing step.
  - Add playlist-level aggregate progress with visible per-entry status and output path.

- [ ] **Downloader Feature Surface**
  - Implement format selection with friendly labels for resolution, codec, bitrate, filesize, container and protocol.
  - Implement playlist support with item selection, batch queueing, skip completed, retry failed and stop-on-error controls.
  - Implement subtitle download, automatic subtitle selection, thumbnail download, metadata sidecar output and metadata writing.
  - Implement cookie support, username/password login, two-factor prompt handoff, proxy settings, user agent/referrer headers and site-specific options.
  - Implement retry controls, socket timeout, rate limit, concurrent fragment settings, max downloads, archive/history and batch URL import.
  - Implement audio-only extraction and post-processing workflows: remux, extract audio, embed subtitles, embed thumbnails, write metadata, split chapters and hand completed files to conversion profiles.

- [ ] **Converter Inventory Port/Integration**
  - Expose the complete tracked conversion capability inventory in Playlizt: 273 encoders, 607 decoders, 185 muxers, 367 demuxers, 596 filters, 51 bitstream filters and 55 protocols.
  - Add automated capability verification that fails when any inventory count drops below the tracked requirement.
  - Surface capability details through typed Playlizt models for codecs, containers, filters, protocols, hardware acceleration support and invalid combination diagnostics.

- [ ] **Media Probe And Conversion Queue**
  - Add media probe support for streams, chapters, attachments, duration, bitrate, resolution, framerate, color details, audio layout, subtitle streams and container metadata.
  - Implement conversion jobs with pending, probing, running, completed, failed, cancelled and retriable states.
  - Add queue persistence, cancellation, retry, output path handling, output collision policy and completed-output Library import.
  - Add Playlizt conversion progress bars with parsed media time, percent, speed, ETA, output size and current processing stage.

- [ ] **Converter Workflows And Controls**
  - Implement presets for MP3, AAC, FLAC, WAV, MP4 720p, MP4 1080p, remux, audio-only, web clip, mobile-friendly video and custom profile.
  - Implement advanced codec/container/filter controls for encoder, decoder, muxer, demuxer, bitrate, CRF, sample rate, channels, pixel format, subtitle handling and filter chains.
  - Implement clip, trim, crop, scale, normalize audio, extract audio, remux, transcode, subtitle burn-in, subtitle copy, thumbnail generation, short-clip export and stream-copy workflows.
  - Validate every selected combination before execution and show friendly correction messages when a combination is invalid.

- [ ] **VLC-Class Playback, Network And Device Features**
  - Implement local file playback, Library item playback, remote HTTP/HLS/DASH/RTSP-style network streams and playlist entry playback under a Playlizt-specific interface.
  - Implement audio track, video track, subtitle track and external subtitle selection.
  - Implement playback speed, seek, resume, chapter navigation, snapshots and local continue-watching state.
  - Implement hardware acceleration paths with an explicit setting for the active path.
  - Implement renderer/casting discovery, service discovery, device online/offline/error state and remote playback controls: connect, play, pause, seek, volume, disconnect and transfer playback back to local.
  - Implement stream output/transcoding profiles so local items or network streams can be sent to another target in a compatible format.

- [ ] **Library, Folder Scanning, Search/Sort/Filter**
  - Implement recursive and non-recursive folder scanning from Settings.
  - Store local `LibraryItem` records with path, display title, duration, media type, hash, source, parent/derived lineage, date added and last-seen timestamp.
  - Implement search, sort and filters by title, folder, source, type, duration, date added and missing-file state.
  - Import completed downloads and completed conversions as first-class Library items when enabled.

- [ ] **Mixed Local/Remote Playlists**
  - Implement playlist CRUD, duplicate, rename, delete, drag/drop ordering and stable local persistence.
  - Support mixed local Library items, online catalog content, downloader URLs, downloaded outputs and converted outputs in the same playlist.
  - Resolve unavailable local files and unavailable online content with visible per-item errors instead of dropping entries.

- [ ] **Settings Wired To Behaviour**
  - Wire scan folders, recursive scan, default download folder, max concurrent downloads, archive/history, converter output folder, hardware acceleration, renderer discovery and startup tab directly into their consuming services.
  - Prove each setting takes effect immediately and persists across restart.

- [ ] **Major Workflow Tests**
  - Add automated tests for downloader inventory, extraction, format selection, playlist downloads, subtitle/thumbnail/metadata outputs, cookies, proxy settings, retries, archive/history, batch import, audio-only and post-processing.
  - Add automated tests for converter inventory, probe parsing, preset validation, clip/trim/crop/scale/normalize/extract-audio/subtitle-burn workflows, queue persistence, cancel/retry and Library import.
  - Add automated tests for network streams, device discovery/control state, stream output/transcoding validation, hardware acceleration settings, folder scanning, search/sort/filter, mixed playlist items and settings propagation.

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
- [x] **Global Navigation Shell**: Replace the current single-page dashboard shell with a reusable root `Scaffold` that hosts a minimal top app bar (Playlizt/Blaklizt branding and a hamburger icon) and a tab-aware body.
  - Use a **single navigation rail** on the left that is present on all platforms; remove the bottom `BottomNavigationBar` entirely so there is only one tab bar.
  - The navigation rail exposes 6 fixed tabs in this exact order: **Library**, **Playlists**, **Streaming**, **Download**, **Convert**, **Devices**.
  - Each tab is backed by a dedicated root screen widget (e.g. `LibraryTabScreen`, `PlaylistsTabScreen`, etc.) with its own internal scroll / state, preserved when switching tabs.
  - All tab content must be **top-aligned** within its scrollable area; only the "Powered by Blaklizt Entertainment" footer strip in the Streaming tab is bottom-aligned.
  - The selected tab uses an oval/pill highlight that clearly surrounds but does not visually obscure the tab icon or label in either Light or Dark theme (fixing the light-mode overlap issue).
  - The T3Ratech logo is removed from the global header strip and instead rendered at the very top of the Settings drawer.
  - Interactive controls such as theme toggle, upload shortcut, analytics/dashboard entry point, profile details and logout are removed from the top app bar and surfaced as actions inside the Settings drawer.

- [x] **Streaming Tab Migration**: Move all existing online/dashboard behaviours into the **Streaming** tab.
  - Relocate the content grid, search input, category chips, AI recommendation section, "Continue Watching" strip, and any online-only calls into the Streaming tab body.
  - Ensure the "Powered by Blaklizt" footer is rendered only within the Streaming tab’s scroll view, at the bottom of the content list.
  - When the backend is unavailable, the Streaming tab should fail fast with a clear error state (no silent fallbacks to local-only views inside this tab).

- [x] **Tab State & Routing**: Persist which tab is currently selected and restore it on app restart.
  - Integrate with existing routing/navigation (e.g. named routes or `onGenerateRoute`) so that direct deep links such as `/#/streaming` or `/#/download` open the correct tab.
  - Ensure video playback screens can be launched from any tab while keeping the shell navigation consistent when popping back.

#### 5.2 Library Tab – Local Media Shell (Phase 1: UI)
- [x] **Library Landing UI**: Implement a Library tab landing view focused on local files (offline-first).
  - Show a summary header section (e.g. "Local Library") with quick stats for total items and last scan time.
  - Provide primary actions: **Scan Folders**, **Rescan Now**, and **Open Folder**.

- [x] **Folder/Item Browser (Read-Only Phase)**:
  - Render a 2–3 column grid/list of media items inspired by desktop players (e.g. artists/albums/tracks), but initially backed by a basic filesystem listing from configured scan folders.
  - Support simple sort toggles (by Name, Date Added) and a text search box scoped to local items.
  - Tapping an item routes into the existing playback flow with a `file://` media source, distinct from streaming URLs.

- [ ] **Library Indexing Contract (Design Only)**:
  - Define a local `LibraryItem` model (ID, path, display title, duration, media type, hash) with clear separation from backend `Content` DTOs.
  - Decide where lightweight indexing metadata is stored (e.g. local SQLite/Isar file) without yet implementing full indexing logic.
  - Document that subsequent phases will implement actual background scanning and incremental updates based on this contract.

#### 5.3 Playlists Tab – Unified Local/Online Lists (Phase 1: UI)
- [x] **Playlists Landing UI**:
  - Display a list of playlists showing name, number of items, and whether the playlist is **Local**, **Online**, or **Hybrid**.
  - Add actions to **Create Playlist**, **Rename**, **Delete**, and **Duplicate** playlists.

- [x] **Playlist Editor Shell (UI)**:
  - Implement a playlist editor screen where users can see the ordered list of items and re-order via drag-and-drop.
  - Items can reference either local `LibraryItem` entries or online `Content` entries; the UI should visually distinguish these (e.g. icon or chip), even if hybrid resolution is implemented later.

#### 5.4 Download Tab – Download Manager UI
- [x] **Download Input Row**:
  - At the top of the Download tab, render a single-line URL input box and a `Download` button aligned horizontally (desktop) or stacked with responsive layout (mobile).
  - The input accepts any HTTP/HTTPS media URL (initially focusing on direct file URLs; YouTube-style extraction will be layered on later).
  - Disable the `Download` button while the URL is empty or clearly invalid according to a strict URL pattern.

- [x] **Default vs Custom Location Switch**:
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

- [x] **Download Engine Abstraction (Local Only, No Backend Dependency)**:
  - Implement a `DownloadManager` service in Flutter that handles multiple concurrent HTTP downloads using a configurable maximum concurrency and supports pause/resume where protocol allows, otherwise cancel/restart semantics.
  - Expose a stream-based API so the UI can subscribe to download state updates and update the progress panel in real time.
  - Enforce strict error handling and surface clear error messages in the UI (e.g. network errors, disk full, permission denied) rather than silently swallowing failures.

- [x] **youtube-dl Extractor/Downloader Runtime (Desktop)**:
  - Verify the existing native Dart extractors and remove placeholder extractor registrations from the production stack.
  - Package the extractor runtime with the Flutter workspace and use it after native extractors and before the generic fallback.
  - Persist youtube-dl-backed queued downloads with explicit backend metadata so restarts preserve queue state and active downloads fail clearly.
  - Verify the packaged extractor runtime exposes 1,273 extractors and cover the mapper, inventory check, extractor registration and task persistence with Flutter tests.

#### 5.5 Convert Tab – Conversion Workspace
- [x] **Convert Landing UI Contract**:
  - Provide a simple UI to pick one or more existing Library items and a target output profile (e.g. MP3, MP4 720p, Audio-only, Clip segment).
  - Expose fields for start/end timestamps (HH:MM:SS) for clipping scenarios.
  - Finalise the UI contract and model objects (`ConversionJob`) used by the conversion engine.

- [ ] **Conversion Queue Panel**:
  - Mirror the visual style of the Download queue panel for conversion jobs (Pending, Running, Completed, Failed, Cancelled), with progress indicator and per-item controls.

#### 5.6 Devices Tab – Playback Targets
- [x] **Devices Landing UI**:
  - Show a list for local and network playback targets (e.g. "This Device", "Living Room TV", "Bluetooth Speaker") with explicit online/offline/error states.
  - Define a `PlaybackDevice` abstraction (ID, name, type, capabilities) for real device discovery and renderer control.

#### 5.7 Global Settings & Hamburger Menu
- [x] **Hamburger Menu Entry Point**:
  - Add a three-line hamburger icon to the minimal top app bar that opens a side drawer or full-screen settings page.
  - The hamburger is the single entry point into Settings; the top app bar no longer exposes theme, upload, analytics or profile controls directly.

- [x] **Settings Structure**:
  - **General**: default start-up tab, language/locale (if applicable), behaviour when backend is unreachable, and per-user **tab visibility** configuration.
    - When running on Flutter Web, the Library and Devices tabs cannot be enabled; Streaming must always be visible and acts as the default start-up tab.
    - Whenever the visible tab set changes, the saved start-up tab must be updated to a still-visible tab (falling back to Streaming if necessary).
  - **Library**: list of **scan folders** with add/remove controls, recursive scan toggle, and a button to trigger a manual rescan.
  - **Download**: default download location editor (synchronised with the Download tab switch), maximum concurrent downloads, and whether to auto-import successful downloads into the Library. Even when **"Use default download location"** is ON, the user can open a native folder chooser dialog from Settings to change the default folder.
  - **Appearance**: default theme (Light/Dark/System), accent colour choice, and options for compact vs spacious layout. The **default theme for new users and anonymous sessions is Dark mode**.
  - **Playback**: default playback speed, enable/disable "Continue Watching" for local items, and whether to remember per-item positions.
  - **Account & Actions**: cluster global actions such as upload content, analytics/dashboard entry point, profile details and logout into dedicated tiles inside Settings.

- [x] **Settings Persistence**:
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
- [ ] **Test Standardization (Patrol 4.0)**:
  - [ ] Migrate all Flutter integration tests and Java Playwright tests to Patrol 4.0.
  - [ ] Implement scalable download test (save to `/tmp`, playlist check, playback 10s, min volume) for multiple sites.
  - [ ] Remove legacy Flutter integration tests and Java Playwright tests.
- [ ] **File Header Template Rollout**: Apply the Windsurf file header template to all applicable source files (Java, Dart, shell scripts, etc.) using the per-file creation timestamp (format `YYYY/MM/DD HH:MM`) obtained via shell commands for each file.

---

## ✅ Recently Completed
- [x] **Local Media Engine Implementation Slice**: Added real Flutter services and UI wiring for Library folder scanning/index persistence, Playlists CRUD/reorder UI, FFmpeg/FFprobe-backed conversion job queue/progress/cancel/retry scaffolding, completed conversion Library import, richer downloader metadata/progress models, playlist-aware downloader queue entries, completed download Library import, and focused tests for library/conversion/downloader model behaviour.
- [x] **Library Filter And Availability Slice**: Added Library item availability state, missing-file checks, missing counters, media-type/source/missing filters, disabled playback for missing local files, web manager parity and tests for typed filtering plus deleted imported media visibility.
- [x] **Devices And Network Streams Slice**: Added persistent device/network stream models, a `DeviceManager`, Devices tab controls for renderer discovery and hardware acceleration settings, add/remove/play network stream workflows, local playback handoff, and tests for stream persistence plus URL validation.
- [x] **Renderer Discovery And Control Slice**: Added platform renderer discovery plumbing with desktop SSDP probing, discovered renderer state, connect/disconnect/play/pause/resume/stop/seek/volume command handling, Devices tab casting controls, and deterministic tests for discovery settings plus remote playback state.
- [x] **Downloader Options Slice**: Added persisted downloader options for explicit format selectors, audio-only extraction, subtitle sidecars, thumbnails, media metadata, proxy and rate-limit settings; wired the Download tab controls to queued tasks and the desktop downloader runtime; added tests for option persistence and structured progress parsing.
- [x] **Downloader Cookie And Login Slice**: Added cookie file and username/password controls to the Download tab, passes them to the desktop downloader runtime, persists cookie/username settings with queued tasks, and keeps raw passwords memory-only instead of writing them to local task JSON.
- [x] **Downloader Archive And History Slice**: Added persisted completed-source archive entries, a skip-archived-downloads setting, skipped queue rows with friendly status text, archive clear controls, completion recording for desktop and web downloads, and tests for archive JSON, settings persistence and duplicate skip behaviour without network access.
- [x] **Downloader Batch Queue Slice**: Added a typed batch URL parser, desktop/web batch enqueue APIs, a multiline Batch URLs control in the Download tab, one-folder custom destination handling for multi-URL jobs, and tests for duplicate/comment/malformed batch parsing.
- [x] **Downloader Retry/Header Controls Slice**: Added retry, fragment retry, socket timeout, user-agent and referrer options; persists them with queued tasks; passes them to the desktop youtube-dl runtime; applies headers/timeouts/retry attempts to native direct downloads and HLS requests; and tests option persistence.
- [x] **Downloader Resource Controls Slice**: Added concurrent-fragment and max-download controls, persisted them with download tasks, capped local batch and playlist expansion before queueing, passed the controls into the downloader runtime and tested option persistence, validation and generated arguments.
- [x] **Downloader Sidecar Output Slice**: Added persisted subtitle/thumbnail/metadata sidecar records, youtube-dl completion-time sidecar discovery, per-task sidecar chips in the Download tab, and tests for sidecar classification, language extraction and JSON persistence.
- [x] **Downloader Site And Playlist Options Slice**: Added playlist start/end/items, match-title, reject-title, age-limit, geo-bypass, geo-verification proxy and force-playlist controls; persisted them on download tasks; passed them into youtube-dl command construction; and tested exact argument generation.
- [x] **Converter Capability Catalog Slice**: Added typed FFmpeg capability entries for encoders, decoders, muxers, demuxers, filters, bitstream filters and protocols; exposed a desktop catalog loader with protocol input/output direction support; added a Convert tab capability inspector with search/section filtering; and tested catalog parsing/search.
- [x] **Downloader Preview Slice**: Added Playlizt download preview models for extractor metadata, formats, subtitles, thumbnails, warnings and playlist entries; exposed preview loading through desktop/web download managers; added a Download tab preview panel with format selection handoff; and tested preview normalization from extractor output.
- [x] **Playback Hardware Acceleration Wiring Slice**: Added a typed playback engine configuration, read the persisted hardware acceleration setting before app startup, passed decoder preferences into native video backend registration, kept web registration aligned, and tested both hardware-preferred and forced-software decoder option payloads.
- [x] **Player Subtitle And Snapshot Slice**: Added direct-player controls for external subtitle files/URLs and frame snapshots through the native playback extension surface; wrote snapshots as PNG files under the user's Pictures/Playlizt folder; surfaced backend capability errors clearly; and tested stable snapshot filename generation.
- [x] **Converter Advanced Validation Slice**: Added capability-catalog validation for custom container, video encoder, audio encoder, video filter and audio filter choices; wired the Convert tab to block invalid advanced options with friendly messages when a catalog is loaded; and tested valid/invalid catalog combinations.
- [x] **Converter Custom Profile Slice**: Added a persisted custom conversion profile that accepts user-supplied FFmpeg output arguments, exposes the control in the Convert tab, passes custom arguments into queued jobs, and tests command construction plus job JSON persistence.
- [x] **Converter Advanced Controls Slice**: Added structured container, video/audio codec, bitrate, CRF, sample-rate, channel, pixel-format, video/audio filter and subtitle-mode controls; persisted them on conversion jobs; wired them into desktop/web enqueue paths and FFmpeg argument generation; and tested argument construction, validation and JSON persistence.
- [x] **Converter Collision Policy Slice**: Added a settings-backed output conflict policy for file conversions with keep-both, overwrite and fail-before-queue behavior; wired it into desktop output path planning, exposed it in Settings and tested persistence plus path resolution without starting services.
- [x] **Media Probe UI Slice**: Added reusable FFprobe JSON mapping for container metadata, size, duration, bitrate, stream codec details, frame rates and language tags; wired the Convert tab Probe action and inline stream summary; and tested probe mapping without requiring FFprobe or backend services.
- [x] **Media Probe Detail Slice**: Added chapter and attachment parsing, cover-art detection, stream color/channel metadata, richer Convert tab probe summaries, and focused ffprobe JSON mapping coverage without requiring services.
- [x] **Converter Workflow Presets Slice**: Added first-class Thumbnail, GIF Clip and WebM Clip output profiles with generated FFmpeg arguments and output extensions, expanding short-clip and thumbnail workflows beyond raw custom arguments; added tests for each generated preset.
- [x] **Stream Output Transcoding Slice**: Added RTMP, RTSP, UDP MPEG-TS, HLS Live and audio MP3 stream-output profiles; queued stream jobs through the existing conversion progress/cancel/retry flow; added protocol validation, web hard-failure handling, Convert tab File/Stream mode controls and tests for generated FFmpeg arguments plus stream-job persistence.
- [x] **Playback Controls And Local Resume Slice**: Added local playback position persistence, direct-video Playlizt controls for play/pause, seek slider, 10-second skip, playback speed selection and resume from local history, while preserving backend playback tracking for logged-in users; added tests for local history persistence and progress calculation.
- [x] **Database Migration**: Switched from Flyway to Hibernate Auto-DDL (`create`).
- [x] **Data Seeding**: Implemented `import.sql` for initial user (`tkaviya`) and content (Tha Streetz TV).
- [x] **Auth Service**: User registration and Login (JWT) for a single generic authenticated user (no roles).
- [x] **Basic Dashboard**: Home screen with content grid and search.
- [x] **AI Recommendations & UI Tests**: Implemented "Recommended for You" UI, category chips and sentiment labels, plus stabilized Playwright flows (authentication, dashboard, recommendations, and video playback with crash-safe navigation).
 - [x] **UI Test Harness Hardening**: Enabled Flutter Semantics at startup and added Semantics labels to critical headings so Playwright can reliably detect UI elements.
 - [x] **UI Alignment Tweaks**: Streaming tab content top-aligned (footer excluded) and T3raTech logo centered in the Settings drawer.
