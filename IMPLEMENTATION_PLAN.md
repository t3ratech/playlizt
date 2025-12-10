# Playlizt Implementation Plan

This document tracks the outstanding tasks and features to be implemented.
**Rule:** All new feature requests must be added here first, then marked as completed when done.

## 🚀 Outstanding Features

### Hybrid Offline/Online Refactor Framework (Framework Only)

- [ ] Rename services and schemas to use `playlizt-` prefixes (e.g. `playlizt-api-gateway`, `playlizt-authentication`, `playlizt_content`, `playlizt_playback`).
- [ ] Introduce `playlizt-content` multi-module parent with `playlizt-content-api` and `playlizt-content-processing` submodules, aligned with Groovy Gradle DSL.
- [ ] Rename top-level environment variables to `PLAYLIZT_*` and propagate through `.env`, `docker-compose.yml`, `playlizt-docker.sh`, and Terraform.
- [ ] Update Dockerfiles, `docker-compose.yml`, Terraform `services.tf`, and `playlizt-docker.sh` to use the new service and module names.
- [ ] Update `ARCHITECTURE.md` and `README.md` to the new hybrid offline/online architecture (tabs, modules, naming, Groovy Gradle).
- [ ] Run builds and all tests (unit + Playwright) after the framework changes and fix any failures caused by the refactor.

### Generic User Model (Remove Roles)

- [ ] Replace the role-based model (USER/CREATOR/ADMIN) with a single generic authenticated user in `ARCHITECTURE.md` and `README.md`.
- [ ] Update authentication and security configuration to remove `role` from JWT payloads and rely on basic authenticated vs anonymous checks only.
- [ ] Update database schema and seed data to drop the `role` column from `users` and any creator/admin-specific constraints, while keeping ownership information for content.
- [ ] Update the Flutter frontend (login/register, dashboards, analytics views) to remove role selection and make upload/stats features available to all authenticated users.
- [ ] Update unit tests, integration tests and Playwright UI tests to reflect the generic user model with no roles.
- [ ] Run the `/test-playlizt-ui` workflow and manually verify all screenshots after the role removal changes are in place.

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
- [ ] **AI Recommendations UI**: "Recommended for You" section based on AI.
- [ ] **Category Browsing**: Filter content by category chips.
- [ ] **Sentiment Display**: Show AI rating and sentiment on content cards.

### 6. Security & Authentication
- [x] **User Registration**: Simple registration flow for a generic authenticated user (no roles).
- [x] **Flexible Login**: Support login via Username or Email.
- [x] **Strong Hashing**: Enforce Argon2id for password storage.
- [x] **UX Improvements**: Enter key submission and clear validation.
- [ ] **MFA**: Multi-Factor Authentication (Future).
- [x] **Analytics Dashboard**: Insights for usage and engagement.
- [x] **Profile Management**: User profile editing and settings.
- [x] **"Continue Watching" UI**: Horizontal list of unfinished videos.

### 6. Infrastructure & Testing
- [x] **GCP Infrastructure**: Terraform configuration for Cloud Run & Cloud SQL.
- [x] **Integration Tests**: Testcontainers-based integration tests for all services.
- [x] **End-to-End Tests**: Full flow testing (Frontend -> Gateway -> Service -> DB).
- [x] **Log Management**: Centralized logging setup.
- [ ] **Production Hardening**: Security headers, Https, etc.

---

## ✅ Recently Completed
- [x] **Database Migration**: Switched from Flyway to Hibernate Auto-DDL (`create`).
- [x] **Data Seeding**: Implemented `import.sql` for initial user (`tkaviya`) and content (Tha Streetz TV).
- [x] **Auth Service**: User registration, Login (JWT), Role-based access.
- [x] **Basic Dashboard**: Home screen with content grid and search.
