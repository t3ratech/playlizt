# Playlizt - Media Player, Streamer, Downloader & Converter

Playlizt is a media player, streamer, downloader and converter for your own media collection. It plays local audio and video files, manages playlists and libraries, can stream from the Playlizt backend when available, and can download or convert media for offline use. When connected to the backend, it also offers AI-powered discovery, metadata enhancement and analytics.

Primary areas:
- **Library**: Browse and search local audio/video files.
- **Playlists**: Build playlists that can mix local and online items.
- **Streaming**: When online, access the Playlizt backend catalog.
- **Download**: Download external media to a configured or chosen folder, with optional Library integration.
- **Convert**: Transcode/clip media into library-friendly formats.
- **Devices**: Extensibility point for future sync/cast targets.

### Navigation Shell & Tabs

The Flutter frontend uses a unified multimedia shell:

- **Global App Bar** (top):
  - Shows the Playlizt/Blaklizt wordmark.
  - Contains a hamburger icon that opens the Settings drawer.
  - Does **not** expose theme, upload, analytics or profile controls directly; those live inside Settings.

- **Left Navigation Rail** (all platforms):
  - Single, fixed tab bar in this order: **Library**, **Playlists**, **Streaming**, **Download**, **Convert**, **Devices**.
  - There is **no bottom tab bar**; the navigation rail is the only source of truth for tab state.
  - Each tab hosts its own scrollable content while preserving state when switching tabs.
  - Tab content is visually **top-aligned** to match traditional desktop media players.
  - The selected tab uses an oval/pill highlight that surrounds, but does not obscure, the tab icon/label in Light and Dark themes.

- **Library Tab**:
  - Entry point into the local media library.
  - Surfaces indexed folders and items from configured scan folders.
  - Supports basic browsing and search over local audio/video files.

- **Playlists Tab**:
  - Manages user playlists for local and online items.
  - Provides list and detail views, with ordering and future editing capabilities.

- **Streaming Tab**:
  - Hosts all online content features: search bar, category chips, AI "Recommended for You" carousel, "Continue Watching" strip, and main content grid.
  - The "Powered by Blaklizt Entertainment" footer (logo, line and text) is bottom-aligned within this tab and does **not** appear on other tabs.
  - When the backend is unavailable, the tab shows a clear error state instead of silently falling back to local-only views.

- **Download Tab**:
  - URL input field plus `Download` button to enqueue downloads from external HTTP/HTTPS sources.
  - Switch to choose between using a **default download folder** (`~/Downloads` by default, user-editable) or prompting for a folder/name on each download.
  - Scrollable download queue panel listing active and recent downloads with status, progress bar, and per-item controls to **Pause**, **Resume**, or **Cancel**.
  - Backed by a `DownloadManager` service that performs real HTTP downloads, enforces a configurable concurrency limit, and persists task state across app restarts.

- **Convert Tab**:
  - Dedicated area for transcoding and clipping media into library-friendly formats.
  - Reads from Library items and writes transformed outputs back into the Library.

- **Devices Tab**:
  - Lists current and potential playback targets.
  - Provides a future integration point for sync/cast features without impacting core Library semantics.

- **Settings Drawer** (hamburger menu):
  - Shows the T3Ratech logo at the top, alongside Settings title.
  - **General**: choose startup tab (Library/Playlists/Streaming/Download/Convert/Devices) and configure which tabs are visible.
    - On the web platform, the **Library** and **Devices** tabs cannot be enabled; **Streaming** must always be visible and acts as the default startup tab.
    - Whenever the visible tab set changes, the saved startup tab is automatically adjusted to a still-visible tab (falling back to Streaming if needed).
  - **Library**: manage **scan folders** via add/remove list of filesystem paths.
  - **Download**: view and edit the default download folder; toggle "Use default download location" behaviour. Even when the switch is ON, you can open a native folder chooser dialog from Settings to update the default folder.
  - **Appearance**: light/dark theme toggle. The default theme for new users and anonymous sessions is **Dark mode**.
  - **Account & Actions**: access upload, analytics/dashboard, profile details and logout; these actions are no longer duplicated in the top app bar.

## Local Media Features (Offline)

These features work entirely on your local machine without any backend:

### 1. Library
- Scans configured folders for supported audio/video files.
- Builds a lightweight index of your media collection.
- Lets you browse by folder and search over basic metadata.

### 2. Playlists
- Stores ordered lists of Library items.
- Supports purely local playlists and hybrid playlists (local + online entries).
- Keeps playlist entries stable as long as the underlying files remain on disk.

### 3. Offline Playback
- Plays media directly from the filesystem.
- Tracks last position per item to enable local "Continue Watching".
- Persists minimal playback state so you can resume after restarts.

### 4. Download
- Downloads media to a configured or chosen folder using the original filename by default.
- Optionally normalizes file names and target folders according to Library rules when enabled.
- Optionally ingests successful downloads into the Library as first-class entries.
  
The Download tab surfaces these behaviours via the URL input, default/custom destination switch, and a full download manager queue with pause/resume/cancel controls.

### 5. Convert (Transcoding/Clipping)
- Reads media from the Library and writes converted outputs back into it.
- Supports format conversion, downsampling, or clipping segments.
- Treats converted outputs as separate, trackable Library items.

### 6. Devices (Extensibility Point)
- Provides an abstraction layer for external playback targets.
- Keeps device-specific logic separate from core Library/Player behaviour.
- Designed so that future sync/cast features do not change Library semantics.

## Optional Online Features

Authentication is recommended but optional. The login screen also exposes a **"Continue without login"** option, which starts an anonymous session with limited capabilities: you can browse public catalogue data and use purely local features (Library, Playlists, Download playback), but uploading content, editing profiles, viewing analytics and any other database-backed actions require a logged-in user.

### Online Features (Authenticated Users)
- **Browse Content**: Discover videos by category, tags, or search.
- **AI-Powered Recommendations**: Get personalized content suggestions based on your viewing history.
- **Watch Videos**: Stream content with playback controls.
- **Viewing History**: Track what you've watched.
- **Continue Watching**: Pick up where you left off.
- **Rate & Review**: Provide feedback on content.
- **Upload Content**: Add new videos with title, description, and tags.
- **AI Metadata Enhancement**: Automatically generate improved descriptions, relevant tags, and predicted categories.
- **Manage Content**: Edit or remove your uploaded videos.
- **Analytics & Insights**: View usage and engagement stats for your content and overall catalogue.

## AI-Powered Features

### 1. Smart Recommendations
The platform analyzes your viewing history, preferred genres, and content tags to suggest videos you'll love.

### 2. Metadata Enhancement
When creators upload content, AI automatically:
- Generates improved, SEO-friendly descriptions
- Suggests relevant tags
- Predicts the most appropriate category
- Calculates content relevance scores
*(Powered by async Metadata Enhancer Worker with Gemini API Fallback)*

### 3. Watch Pattern Analysis
Playlizt provides AI-generated insights including:
- Trending content themes
- Peak usage times
- Engagement anomalies
- Viewer behavior clusters

### 4. Sentiment Analysis
Analyzes user comments and ratings to determine sentiment (Positive, Neutral, Negative) with confidence scores.

## Technology

- **Backend**: Java 25, Spring Boot microservices
- **Frontend**: Flutter (Web & Mobile)
- **Database**: PostgreSQL 17
- **AI**: Google Gemini API
- **Security**: Argon2id password hashing, JWT authentication
- **API**: RESTful with OpenAPI/Swagger documentation
- **Deployment**: Docker containers

## Quick Start

### Prerequisites
- Docker and Docker Compose
- JDK 25 (for development)
- Flutter SDK 3.24+ (for frontend development)
- Gemini API key from Google

### Environment Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd Playlizt
```

2. Create `.env` file:
```bash
cp .env.example .env
```

3. Configure environment variables in `.env`:
```properties
# Database
PLAYLIZT_DB_NAME=playlizt
PLAYLIZT_DB_USER=playlizt_user
PLAYLIZT_DB_PASSWORD=your_secure_password

# JWT
PLAYLIZT_JWT_SECRET=your_jwt_secret_minimum_256_bits

# Gemini AI
PLAYLIZT_GEMINI_API_KEY=your_gemini_api_key

# Ports
PLAYLIZT_EUREKA_PORT=4761
PLAYLIZT_DB_PORT=4432
PLAYLIZT_AUTH_PORT=4081
PLAYLIZT_CONTENT_API_PORT=4082
PLAYLIZT_PLAYBACK_PORT=4083
PLAYLIZT_CONTENT_PROCESSING_PORT=4084
PLAYLIZT_API_GATEWAY_PORT=4080
```

### Running the Platform

**Start all services**:
```bash
./playlizt-docker.sh --rebuild-all
```

**Check service status**:
```bash
./playlizt-docker.sh --status
```

**View logs**:
```bash
./playlizt-docker.sh --logs playlizt-authentication
./playlizt-docker.sh --logs --tail all -f playlizt-content-api
```

**Stop all services**:
```bash
./playlizt-docker.sh --cleanup
```

## Deployment

### Google Cloud Platform (GCP)
The project includes automated scripts for deploying the full stack to GCP using Terraform.

1.  **Setup Credentials**: Configure `~/gcp/credentials_playlizt` with your project details.
2.  **Provision & Deploy**:
    ```bash
    ./playlizt-docker.sh --deploy
    ```

This script (invoking `playlizt-ops/scripts/setupGCP.sh`) handles:
- Artifact Registry creation
- Docker image build and push
- Cloud SQL (Postgres 17) provisioning
- Cloud Run service deployment

For detailed instructions, see [ARCHITECTURE.md](ARCHITECTURE.md#end-to-end-deployment).

## API Documentation

Once the services are running, access the API documentation:

- **API Gateway Swagger**: http://localhost:4080/swagger-ui.html
- **Auth Service Swagger**: http://localhost:4081/swagger-ui.html
- **Content Service Swagger**: http://localhost:4082/swagger-ui.html
- **Playback Service Swagger**: http://localhost:4083/swagger-ui.html
- **AI Service Swagger**: http://localhost:4084/swagger-ui.html
- **Eureka Dashboard**: http://localhost:4761

## API Endpoints

### Authentication (`/api/v1/auth`)
- `POST /register` - Register new user
- `POST /login` - Login and get JWT token
- `POST /refresh` - Refresh JWT token
- `POST /logout` - Logout

### Content (`/api/v1/content`)
- `GET /` - List all content (paginated)
- `GET /{id}` - Get content details
- `POST /` - Upload content (authenticated user)
- `PUT /{id}` - Update content (authenticated owner of the content)
- `DELETE /{id}` - Delete content (authenticated owner of the content)
- `GET /search?q=keyword` - Search content
- `GET /categories` - List all categories

### Playback (`/api/v1/playback`)
- `POST /start` - Start playback session
- `POST /update` - Update watch position
- `POST /complete` - Mark video as completed
- `GET /history` - Get viewing history
- `GET /continue` - Get "Continue Watching" list

### AI (`/api/v1/ai`)
- `GET /recommendations` - Get personalized recommendations
- `POST /enhance` - Enhance content metadata
- `GET /insights` - Get insights and analytics (authenticated user)
- `POST /sentiment` - Analyze sentiment

## Example API Usage

### Register a User
```bash
curl -X POST http://localhost:4080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "SecurePass123!"
  }'
```

### Login
```bash
curl -X POST http://localhost:4080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123!"
  }'
```

### Upload Content
```bash
curl -X POST http://localhost:4080/api/v1/content \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Introduction to AI",
    "description": "Learn AI basics",
    "category": "EDUCATION",
    "tags": ["AI", "machine learning", "tutorial"],
    "thumbnailUrl": "https://example.com/thumb.jpg",
    "videoUrl": "https://example.com/video.mp4",
    "durationSeconds": 600
  }'
```

### Get Recommendations
```bash
curl -X GET http://localhost:4080/api/v1/ai/recommendations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Testing

### Run All Tests
```bash
./playlizt-docker.sh --test all
```

### Run Unit Tests Only
```bash
./playlizt-docker.sh --test unit
```

### Run Tests for Specific Service
```bash
./playlizt-docker.sh --test unit --tests "*AuthServiceTest"
```

### Run UI Tests (with full environment)
```bash
./playlizt-docker.sh --tests "zw.co.t3ratech.playlizt.ui.*Test" --module playlizt-ui-tests --test-all
```

## Database Management

The platform uses **Hibernate** for automatic schema creation and **SQL Initialization** for data seeding.

### Initial Data
On startup, the database is automatically populated with:
- **User**: `tkaviya` (Email: `tkaviya@t3ratech.co.zw`, Pass: `testpass`)
- **Content**: 5 videos from the "Tha Streetz TV" playlist

### Resetting the Database
To reset the database to its clean, seeded state (wipes all user data!):

1. **Restart the backend services**:
   ```bash
   ./playlizt-docker.sh -r playlizt-authentication playlizt-content-api playlizt-playback
   ```
   
2. **If schema changes were made (Rebuild & Restart)**:
   ```bash
   ./playlizt-docker.sh -rrr playlizt-authentication playlizt-content-api playlizt-playback
   ```

## Troubleshooting

### Services Won't Start
1. Check if ports are available:
```bash
netstat -tuln | grep -E '4080|4081|4082|4083|4084|4761|5432'
```

2. Check logs:
```bash
./playlizt-docker.sh --logs playlizt-database
./playlizt-docker.sh --logs playlizt-eureka-service
```

3. Rebuild services:
```bash
./playlizt-docker.sh -rrrr <service-name>
```

### Database Connection Issues
- Verify `PLAYLIZT_DB_*` variables in `.env`
- Ensure database container is healthy:
```bash
docker ps | grep playlizt-database
```

### AI Features Not Working
- Verify `PLAYLIZT_GEMINI_API_KEY` in `.env`
- Check AI service logs:
```bash
./playlizt-docker.sh --logs playlizt-content-processing
```
- Verify the API key has appropriate permissions

### JWT Token Errors
- Ensure `PLAYLIZT_JWT_SECRET` is at least 256 bits (32 characters)
- Verify token hasn't expired (default: 1 hour)
- Use `/auth/refresh` to get a new token

## Development

For detailed development information, see [ARCHITECTURE.md](ARCHITECTURE.md).

### Project Structure
```
playlizt/
├── playlizt-eureka-service/       # Service discovery
├── playlizt-authentication/       # Authentication & authorization
├── playlizt-content/
│   ├── playlizt-content-api/      # Content management
│   └── playlizt-content-processing/ # AI features
├── playlizt-playback/             # Playback tracking
├── playlizt-api-gateway/          # API gateway
├── playlizt-frontend/             # Flutter frontend
├── playlizt-ops/                  # Ops & deployment scripts
├── playlizt-terraform/            # Terraform infrastructure
├── docker-compose.yml             # Service orchestration
├── playlizt-docker.sh             # Management script
├── .env                           # Environment configuration
├── ARCHITECTURE.md                # Technical documentation
└── README.md                      # This file
```

### Rebuild Specific Service
```bash
./playlizt-docker.sh -rrr playlizt-authentication
```

### View Service Logs in Real-Time
```bash
./playlizt-docker.sh --logs -f playlizt-content-api
```

## Security

- **Passwords**: Hashed using Argon2id (quantum-resistant)
- **Authentication**: JWT tokens with 1-hour expiration
- **Authorization**: Generic authenticated user model (no roles); features are available to any authenticated user, while unauthenticated access is limited.
- **Containers**: Run as non-root user
- **Secrets**: Managed via environment variables

## Support

For technical documentation and architecture details, see [ARCHITECTURE.md](ARCHITECTURE.md).

For issues or questions:
1. Check the logs: `./playlizt-docker.sh --logs <service-name>`
2. Review API documentation at http://localhost:4080/swagger-ui.html
3. Consult ARCHITECTURE.md for implementation details

## Contact

For support or inquiries, contact:
- Name: Tsungai Kaviya
- Email: t3ratech.dev@gmail.com

## License

Copyright © 2025 TeraTech Solutions (PVT) Ltd. All rights reserved.

---

**Version**: 1.0.0  
**Built with**: Java 25, Spring Boot 3.4, Flutter, PostgreSQL 17, Google Gemini AI
