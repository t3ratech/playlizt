# Playlizt Implementation Plan

This document tracks the outstanding tasks and features to be implemented.
**Rule:** All new feature requests must be added here first, then marked as completed when done.

## 🚀 Outstanding Features

### 1. Content Service (Port 8082)
- [ ] **Content CRUD**: Full Create/Read/Update/Delete operations for video content.
- [ ] **Category Management**: Admin/Creator APIs to manage content categories.
- [ ] **Tag Management**: System for handling content tags.
- [ ] **Advanced Search**: Full-text search with filters (Category, Tags, Duration).
- [ ] **Gemini AI Integration**: Automated metadata enhancement (Description generation, Tag suggestion).
- [ ] **Creator Upload Flow**: Robust upload handling (S3/Local storage optimization).

### 2. Playback Service (Port 8083)
- [ ] **Session Management**: Tracking active viewing sessions.
- [ ] **View Tracking**: Accurate view counting logic (e.g., 30s threshold).
- [ ] **Watch History**: Storing and retrieving user watch history.
- [ ] **"Continue Watching"**: Endpoint to return partially watched videos.
- [ ] **Engagement Metrics**: Calculating completion rates, drop-off points.

### 3. AI Service (Port 8084)
- [ ] **Recommendation Engine**: Personalized content feed based on history and tags.
- [ ] **Metadata Enhancer Worker**: Async processing of new content.
- [ ] **Watch Pattern Analysis**: Admin insights generation.
- [ ] **Sentiment Analysis**: Analyzing comments/reviews (if implemented).
- [ ] **Gemini API Fallback**: Handling API quotas/failures with fallback models.

### 4. API Gateway (Port 8080)
- [ ] **Rate Limiting**: Implementing request limits per user/IP.
- [ ] **Advanced Routing**: Optimize routes for streaming data.
- [ ] **CORS Tuning**: Fine-grained CORS policies for web/mobile clients.

### 5. Frontend (Flutter)
- [ ] **Video Player**: Full-featured video player (Play/Pause, Seek, Quality).
- [ ] **Creator Dashboard**: UI for uploading and managing content.
- [ ] **Admin Analytics**: Dashboard for platform insights.
- [ ] **Profile Management**: User profile editing and settings.
- [ ] **"Continue Watching" UI**: Horizontal list of unfinished videos.

### 6. Infrastructure & Testing
- [ ] **Integration Tests**: Testcontainers-based integration tests for all services.
- [ ] **End-to-End Tests**: Full flow testing (Frontend -> Gateway -> Service -> DB).
- [ ] **Log Management**: Centralized logging setup.
- [ ] **Production Hardening**: Security headers, Https, etc.

---

## ✅ Recently Completed
- [x] **Database Migration**: Switched from Flyway to Hibernate Auto-DDL (`create`).
- [x] **Data Seeding**: Implemented `import.sql` for initial user (`tkaviya`) and content (Tha Streetz TV).
- [x] **Auth Service**: User registration, Login (JWT), Role-based access.
- [x] **Basic Dashboard**: Home screen with content grid and search.
