# QUESTION 5 — MINI STREAMING PLATFORM: AI-POWERED CONTENT DISCOVERY & ANALYTICS

Build a microservices system for a lightweight video/audio streaming platform.

## Updated Scope – Playlizt Hybrid Offline/Online Media Player

Playlizt has evolved from a pure streaming example into a **hybrid offline/online media manager**.

- **Offline-first**: The application must function completely with only local media available.
- **Online optional**: Streaming, AI, and remote analytics are enabled when network connectivity and backend services are available.

### Primary UI Tabs (Target)

1. **Library**
   - Index and browse local audio/video files on disk.
   - Maintain basic metadata (title, artist, album, duration, file path).

2. **Playlists**
   - Manage playlists that can mix local and online items.
   - Support creation, renaming, reordering, and deletion.

3. **Streaming**
   - Current online catalog experience (e.g. Tha Streetz TV playlist).
   - Uses existing Content, Playback, AI, and Gateway services.

4. **Download**
   - Framework for downloading audio/video from arbitrary streaming URLs (yt-dlp style).
   - Persist downloaded media into the Library so it is available offline.

5. **Convert**
   - Framework for transcoding between formats and clipping segments (ffmpeg-style).
   - Output converted media back into the Library.

6. **Devices**
   - Framework for listing external devices or endpoints (e.g. phone, USB drive, LAN targets).
   - Future support for sync/cast operations.

The remaining sections in this document describe the original streaming-focused requirements from the question and remain as historical context.

## System Requirements

### User Roles
- **USER**: Basic access (browse, watch, history).
- **CREATOR**: Content management access.
- **ADMIN**: Platform management and analytics access.

### Microservices
1. **Auth Service**: User authentication with roles.
2. **Content Service**: Upload metadata, categorize, manage content.
3. **API Gateway**: Entry point for all requests.
4. **Playback Service**: Track views, watch history, engagement.
5. **AI Service**: Intelligent features.

### Frontend (Flutter)
- Browsing content by category or search.
- Viewing/watching a video (metadata-based simulation).
- Tracking viewing history.
- Creator dashboard for uploading new content (title, description, tags, thumbnails).

## AI Requirements (Integrate at least two)

1. **AI Recommendation Engine** (Implemented)
   - Recommend content based on:
     - User viewing history
     - Tags
     - Genre similarity
     - Popularity patterns

2. **AI Metadata Enhancer** (Implemented)
   - When a creator uploads a video, generate using AI:
     - Improved description
     - Relevant tags
     - Predicted category

3. **AI Watch Pattern Analysis** (Planned)
   - Provide the admin with an AI-generated insights summary:
     - Trending themes
     - Peak usage times
     - Engagement anomalies
     - Viewer clusters

## Bonus Points
- [x] Simulate a playback session micro-interaction.
- [x] Implement "Continue Watching".
- [ ] Add content rating & sentiment analysis using AI.

## Constraints
- **Back-end**: Java using Microservices Architecture with Service Discovery.
- **Front-end**: Flutter.
- **Documentation**: Swagger API documentation with examples.
- **Infrastructure**: Docker.
- **Process**: Build backend with API docs and tests BEFORE frontend.
