# Playlizt Implementation Plan

This document tracks the outstanding tasks and features to be implemented.
**Rule:** All new feature requests must be added here first, then marked as completed when done.

## 🚀 Outstanding Features

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
- [x] **Creator Dashboard**: UI for uploading and managing content.
- [x] **Reverse Video Order**: Display videos with Episode 1 at the top and Episode 5 at the end.
- [x] **YouTube Player Integration**: Implement video playback using `youtube_player_flutter`.
- [x] **Creator Registration UI**: Add Role selector to Registration Screen.
- [ ] **AI Recommendations UI**: "Recommended for You" section based on AI.
- [ ] **Category Browsing**: Filter content by category chips.
- [ ] **Sentiment Display**: Show AI rating and sentiment on content cards.

### 6. Security & Authentication
- [x] **Creator Registration**: Allow users to select CREATOR role during registration.
- [x] **Flexible Login**: Support login via Username or Email.
- [x] **Strong Hashing**: Enforce Argon2id for password storage.
- [x] **UX Improvements**: Enter key submission and clear validation.
- [ ] **MFA**: Multi-Factor Authentication (Future).
- [x] **Admin Analytics**: Dashboard for platform insights.
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
