# QUESTION 5 — MINI STREAMING PLATFORM: AI-POWERED CONTENT DISCOVERY & ANALYTICS

Build a microservices system for a lightweight video/audio streaming platform.

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
