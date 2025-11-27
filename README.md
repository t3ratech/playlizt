# Playlizt - AI-Powered Streaming Platform

Playlizt is a lightweight video/audio streaming platform that leverages artificial intelligence to provide intelligent content discovery, automated metadata enhancement, and behavioral analytics.

## Features

### For Users (USER Role)
- **Browse Content**: Discover videos by category, tags, or search
- **AI-Powered Recommendations**: Get personalized content suggestions based on your viewing history
- **Watch Videos**: Stream content with playback controls
- **Viewing History**: Track what you've watched
- **Continue Watching**: Pick up where you left off
- **Rate & Review**: Provide feedback on content

### For Creators (CREATOR Role)
- **Upload Content**: Add new videos with title, description, and tags
- **AI Metadata Enhancement**: Automatically generate improved descriptions, relevant tags, and predicted categories
- **Manage Content**: Edit or remove your uploaded videos
- **View Analytics**: Track views and engagement on your content

### For Administrators (ADMIN Role)
- **Platform Analytics**: Monitor overall platform usage
- **AI Insights**: View trending themes, peak usage times, and engagement patterns
- **User Management**: Manage user accounts and roles
- **Content Moderation**: Review and moderate platform content

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
Administrators get AI-generated insights including:
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
cd Question5
```

2. Create `.env` file:
```bash
cp .env.example .env
```

3. Configure environment variables in `.env`:
```properties
# Database
POSTGRES_DB=playlizt
POSTGRES_USER=playlizt_user
POSTGRES_PASSWORD=your_secure_password

# JWT
JWT_SECRET=your_jwt_secret_minimum_256_bits

# Gemini AI
GEMINI_API_KEY=your_gemini_api_key

# Ports
EUREKA_PORT=4761
AUTH_SERVICE_PORT=4081
CONTENT_SERVICE_PORT=4082
PLAYBACK_SERVICE_PORT=4083
AI_SERVICE_PORT=4084
API_GATEWAY_PORT=4080
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
./playlizt-docker.sh --logs auth-service
./playlizt-docker.sh --logs --tail all -f content-service
```

**Stop all services**:
```bash
./playlizt-docker.sh --cleanup
```

## Deployment

### Google Cloud Platform (GCP)
The project includes automated scripts for deploying the full stack to GCP using Terraform.

1.  **Setup Credentials**: Configure `~/gcp/credentials` with your project details.
2.  **Provision & Deploy**:
    ```bash
    ./playlizt-docker.sh --deploy
    ```

This script (invoking `ops/scripts/setupGCP.sh`) handles:
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
- `POST /` - Upload content (CREATOR)
- `PUT /{id}` - Update content (CREATOR)
- `DELETE /{id}` - Delete content (CREATOR/ADMIN)
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
- `POST /enhance` - Enhance content metadata (CREATOR)
- `GET /insights` - Get admin insights (ADMIN)
- `POST /sentiment` - Analyze sentiment

## Example API Usage

### Register a User
```bash
curl -X POST http://localhost:4080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "SecurePass123!",
    "role": "USER"
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

### Upload Content (as CREATOR)
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

## Database Management

The platform uses **Hibernate** for automatic schema creation and **SQL Initialization** for data seeding.

### Initial Data
On startup, the database is automatically populated with:
- **User**: `tkaviya` (Email: `tsungai.kaviya@gmail.com`, Pass: `testpass`, Role: USER)
- **Content**: 5 videos from the "Tha Streetz TV" playlist

### Resetting the Database
To reset the database to its clean, seeded state (wipes all user data!):

1. **Restart the backend services**:
   ```bash
   ./playlizt-docker.sh -r auth-service content-service playback-service
   ```
   
2. **If schema changes were made (Rebuild & Restart)**:
   ```bash
   ./playlizt-docker.sh -rrr auth-service content-service playback-service
   ```

## Troubleshooting

### Services Won't Start
1. Check if ports are available:
```bash
netstat -tuln | grep -E '4080|4081|4082|4083|4084|4761|5432'
```

2. Check logs:
```bash
./playlizt-docker.sh --logs database
./playlizt-docker.sh --logs eureka-service
```

3. Rebuild services:
```bash
./playlizt-docker.sh -rrrr <service-name>
```

### Database Connection Issues
- Verify `POSTGRES_*` variables in `.env`
- Ensure database container is healthy:
```bash
docker ps | grep playlizt-database
```

### AI Features Not Working
- Verify `GEMINI_API_KEY` in `.env`
- Check AI service logs:
```bash
./playlizt-docker.sh --logs ai-service
```
- Verify API key has appropriate permissions

### JWT Token Errors
- Ensure `JWT_SECRET` is at least 256 bits (32 characters)
- Verify token hasn't expired (default: 1 hour)
- Use `/auth/refresh` to get a new token

## Development

For detailed development information, see [ARCHITECTURE.md](ARCHITECTURE.md).

### Project Structure
```
playlizt/
├── eureka-service/       # Service discovery
├── auth-service/         # Authentication & authorization
├── content-service/      # Content management
├── playback-service/     # Playback tracking
├── ai-service/          # AI features
├── api-gateway/         # API gateway
├── frontend/            # Flutter frontend
├── docker-compose.yml   # Service orchestration
├── playlizt-docker.sh   # Management script
├── .env                 # Environment configuration
├── ARCHITECTURE.md      # Technical documentation
└── README.md           # This file
```

### Rebuild Specific Service
```bash
./playlizt-docker.sh -rrr auth-service
```

### View Service Logs in Real-Time
```bash
./playlizt-docker.sh --logs -f content-service
```

## Security

- **Passwords**: Hashed using Argon2id (quantum-resistant)
- **Authentication**: JWT tokens with 1-hour expiration
- **Authorization**: Role-based access control (RBAC)
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
