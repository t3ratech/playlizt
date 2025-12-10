# Playlizt - AI-Powered Streaming Platform - Technical Architecture Document

## Table of Contents
- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Microservices](#microservices)
- [Technology Stack](#technology-stack)
- [Configuration Standards](#configuration-standards)
- [Build System](#build-system)
- [Database Architecture](#database-architecture)
- [AI Integration](#ai-integration)
- [Security](#security)
- [Testing](#testing)
- [API Standards](#api-standards)
- [Docker & Deployment](#docker--deployment)
- [Operations](#operations)

## Overview

Playlizt is a media player, streamer, downloader and converter for your own media collection. It is implemented as a microservices-based system using Java, Spring Boot and Flutter, and uses Google Gemini AI for intelligent content discovery, metadata enhancement and behavioral analytics.

### Key Features
- User authentication for a single generic user type (no roles)
- AI-powered content recommendations
- AI metadata enhancement for uploads
- AI watch pattern analysis
- Content browsing and search
- Viewing history and "Continue Watching"
- Content upload & management and usage analytics
- API documentation via Swagger
- Full Docker containerization

## System Architecture

At a high level, Playlizt has:

- A Flutter frontend that runs on the user's machine.
- Local media files on disk that the frontend can play directly.
- A backend composed of the API Gateway and microservices, plus PostgreSQL and Gemini, for online catalog, AI, and analytics.

```text
+----------------------+           +---------------------------+
|   Flutter Frontend   |  <----->  |   Local Media Filesystem |
+----------------------+           +---------------------------+

            |
            | HTTP (when backend is available)
            v

+----------------------+           +--------------------------------------+
| playlizt-api-gateway |  ----->   | Auth / Content / Playback / AI Svc  |
+----------------------+           +--------------------------------------+
                                             |
                                             v
                                  +------------------------+
                                  | PostgreSQL, Gemini API |
                                  +------------------------+
```

The frontend can act purely as a local media player using the filesystem. When the backend stack is running, the same frontend also talks to `playlizt-api-gateway` for authenticated access, online catalog features, AI-powered recommendations and usage analytics.

## Microservices

### Service Inventory
1. **playlizt-eureka-service** (4761) - Service discovery
2. **playlizt-authentication** (4081) - Authentication & authorization
3. **playlizt-content-api** (4082) - Content management
4. **playlizt-playback** (4083) - View tracking & analytics
5. **playlizt-content-processing** (4084) - AI features
6. **playlizt-api-gateway** (4080) - Request routing

### Startup Order
```
database → playlizt-eureka-service → playlizt-authentication → playlizt-content-api → playlizt-playback → playlizt-content-processing → playlizt-api-gateway
```

## Technology Stack

### Backend
- **Language**: Java 25
- **Framework**: Spring Boot 3.4.0
- **Service Discovery**: Spring Cloud Netflix Eureka
- **API Gateway**: Spring Cloud Gateway
- **Database**: PostgreSQL 17
- **ORM**: Spring Data JPA
- **API Docs**: Springdoc OpenAPI 3
- **Build**: Gradle 9.2.1 with Groovy DSL
- **Container**: Docker & Docker Compose

### Frontend
- **Framework**: Flutter 3.24+
- **Language**: Dart 3.5+

### AI
- **Provider**: Google Gemini API
- **SDK**: `com.google.genai:google-genai:0.4.0`
- **Model**: `gemini-2.0-flash-exp`

### Security
- **Password**: Argon2id (quantum-resistant)
- **Auth**: JWT tokens
- **Authorization**: Spring Security with a generic authenticated user (no roles)

### Testing
- **Unit**: JUnit 5, Mockito
- **Integration**: Spring Boot Test, Testcontainers
- **Coverage**: 80% minimum

## Configuration Standards

**Core Principle**: All configuration follows strict "no defaults, no fallbacks" – services must fail fast if required configuration is missing or inconsistent.

### Configuration Hierarchy
```
.env → docker-compose.yml → Dockerfile → application-{profile}.properties → Runtime
```

### Mandatory Properties
All services:
- `spring.application.name`
- `server.port`
- `eureka.client.service-url.defaultZone`

Database services:
- `spring.datasource.url` (no default)
- `spring.datasource.username` (no default)
- `spring.datasource.password` (no default)

### Configuration Example

**.env**:
```properties
PLAYLIZT_DB_HOST=playlizt-database
PLAYLIZT_DB_PORT=5432
PLAYLIZT_DB_NAME=playlizt
PLAYLIZT_DB_USER=playlizt_user
PLAYLIZT_DB_PASSWORD=${DB_PASSWORD}

PLAYLIZT_EUREKA_PORT=4761
PLAYLIZT_AUTH_PORT=4081
PLAYLIZT_CONTENT_API_PORT=4082
PLAYLIZT_PLAYBACK_PORT=4083
PLAYLIZT_CONTENT_PROCESSING_PORT=4084
PLAYLIZT_API_GATEWAY_PORT=4080

PLAYLIZT_JWT_SECRET=${JWT_SECRET}
PLAYLIZT_GEMINI_API_KEY=${GEMINI_API_KEY}
```

**docker-compose.yml**:
```yaml
services:
  playlizt-authentication:
    environment:
      - SERVER_PORT=${PLAYLIZT_AUTH_PORT}
      - SPRING_DATASOURCE_URL=jdbc:postgresql://${PLAYLIZT_DB_HOST}:${PLAYLIZT_DB_PORT}/${PLAYLIZT_DB_NAME}
      - PLAYLIZT_JWT_SECRET=${PLAYLIZT_JWT_SECRET}
      - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=${PLAYLIZT_EUREKA_URL}
```

**application-docker.properties**:
```properties
server.port=${SERVER_PORT}
spring.datasource.url=${SPRING_DATASOURCE_URL}
jwt.secret=${PLAYLIZT_JWT_SECRET}
```

## Build System

### Project Structure
```
playlizt/
├── build.gradle
├── settings.gradle
├── gradlew
├── .env
├── docker-compose.yml
├── playlizt-docker.sh
├── playlizt-eureka-service/
├── playlizt-authentication/
├── playlizt-content/
│   ├── playlizt-content-api/
│   └── playlizt-content-processing/
├── playlizt-playback/
├── playlizt-api-gateway/
├── playlizt-frontend/
├── playlizt-ops/
└── playlizt-terraform/
```

### Gradle Commands
```bash
./gradlew clean build                     # Build all
./gradlew :playlizt-authentication:build  # Build specific service
./gradlew test                            # Run all tests
./gradlew :playlizt-authentication:test   # Test specific service
./gradlew bootJar                         # Generate JARs
```

### JAR Naming
Each service generates a uniquely named, fully prefixed JAR, for example:
- `playlizt-eureka-service.jar`
- `playlizt-authentication.jar`
- `playlizt-content-api.jar`
- `playlizt-playback.jar`
- `playlizt-content-processing.jar`
- `playlizt-api-gateway.jar`

**build.gradle** (Groovy):
```groovy
bootJar {
    archiveBaseName = 'playlizt-authentication'
    archiveVersion = ''
    archiveClassifier = ''
}
```

## Database Architecture

### PostgreSQL 17
- **Port**: 5432
- **Database**: playlizt
- **Migrations**: Flyway
- **Testing**: Testcontainers

### Schema
```sql
-- Users (playlizt-authentication)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Content (playlizt-content-api)
CREATE TABLE content (
    id BIGSERIAL PRIMARY KEY,
    owner_user_id BIGINT REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    tags TEXT[],
    thumbnail_url VARCHAR(500),
    video_url VARCHAR(500),
    duration_seconds INTEGER,
    ai_generated_description TEXT,
    ai_predicted_category VARCHAR(100),
    ai_relevance_score DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_published BOOLEAN DEFAULT false
);

-- Viewing History (playlizt-playback)
CREATE TABLE viewing_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    content_id BIGINT REFERENCES content(id),
    watch_time_seconds INTEGER NOT NULL,
    last_position_seconds INTEGER NOT NULL,
    completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, content_id)
);

-- Ratings (playlizt-content-processing)
CREATE TABLE content_ratings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    content_id BIGINT REFERENCES content(id),
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    sentiment VARCHAR(20) CHECK (sentiment IN ('POSITIVE', 'NEUTRAL', 'NEGATIVE')),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, content_id)
);
```

### Indexes
```sql
CREATE INDEX idx_content_owner ON content(owner_user_id);
CREATE INDEX idx_content_category ON content(category);
CREATE INDEX idx_viewing_history_user ON viewing_history(user_id);
CREATE INDEX idx_ratings_content ON content_ratings(content_id);
```

## AI Integration

### Google Gemini API

**Dependency**:
```gradle
implementation 'com.google.genai:google-genai:0.4.0'
```

**Configuration**:
```properties
gemini.api.key=${GEMINI_API_KEY}
gemini.api.model=gemini-2.0-flash-exp
gemini.api.fallback-models=gemini-1.5-flash,gemini-1.5-pro
gemini.api.rate-limit.requests-per-minute=60
```

### AI Features

#### 1. Recommendation Engine
- Analyzes viewing history
- Considers tags and genres
- Factors popularity patterns
- Generates personalized recommendations

#### 2. Metadata Enhancer
- Generates improved descriptions
- Suggests relevant tags
- Predicts content category
- Calculates relevance scores

#### 3. Watch Pattern Analysis
- Identifies trending themes
- Detects peak usage times
- Flags engagement anomalies
- Clusters viewer behavior

#### 4. Sentiment Analysis
- Analyzes comments and ratings
- Determines sentiment (POSITIVE/NEUTRAL/NEGATIVE)
- Provides confidence scores

### Implementation Pattern
```java
@Slf4j
@Service
public class GeminiAiService {
    private final Client client;
    private final List<String> fallbackModels;
    
    public GeminiAiService(String apiKey, String primaryModel, List<String> fallbacks) {
        this.client = Client.builder().apiKey(apiKey).build();
        this.fallbackModels = fallbacks;
    }
    
    public String generateContent(String prompt) {
        for (String model : getAllModels()) {
            try {
                GenerateContentResponse response = client.models.generateContent(
                    model, prompt, null
                );
                return response.text();
            } catch (Exception e) {
                log.warn("Model {} failed: {}", model, e.getMessage());
            }
        }
        throw new AiServiceException("All models failed");
    }
}
```

## Security

### Password Hashing (Quantum-Resistant)
**Algorithm**: Argon2id

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();
    // Salt: 16 bytes, Hash: 32 bytes, Memory: 47104 KB
}
```

### JWT Authentication
```json
{
  "sub": "user@example.com",
  "userId": 123,
  "iat": 1234567890,
  "exp": 1234571490
}
```

**Configuration**:
```properties
jwt.secret=${JWT_SECRET}
jwt.expiration-ms=3600000        # 1 hour
jwt.refresh-expiration-ms=86400000  # 24 hours
```

### Authorization Model (No Roles)
- Single generic authenticated user type; no `role` claim in the JWT.
- All authenticated users can browse content, upload and manage their own content, and view analytics.
- Authorization rules distinguish only between anonymous and authenticated requests (for example, using `isAuthenticated()` in Spring Security).

#### Registration Flow
- **Endpoint**: `POST /api/v1/auth/register`
- **Payload**: `username`, `email`, `password`
- **UI**: Registration screen collects credentials only; there is no role selector.

### Container Security
```dockerfile
RUN groupadd -r playlizt -g 1000 && \
    useradd -r -g playlizt -u 1000 playlizt
USER playlizt:playlizt
```

## Testing

### Testing Pyramid
- **E2E**: 10%
- **Integration**: 20%
- **Unit**: 70%
- **Coverage Target**: 80% minimum

### Unit Test Example
```java
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {
    @Mock private UserRepository userRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @InjectMocks private AuthService authService;
    
    @Test
    void shouldAuthenticateValidUser() {
        // Given
        when(userRepository.findByEmail(anyString()))
            .thenReturn(Optional.of(user));
        when(passwordEncoder.matches(anyString(), anyString()))
            .thenReturn(true);
        
        // When
        AuthResponse response = authService.authenticate("test@test.com", "pass");
        
        // Then
        assertNotNull(response.getToken());
    }
}
```

### Integration Test Example
```java
@SpringBootTest
@Testcontainers
@AutoConfigureMockMvc
class ContentServiceIntegrationTest {
    @Container
    static PostgreSQLContainer<?> postgres = 
        new PostgreSQLContainer<>("postgres:17");
    
    @Autowired private MockMvc mockMvc;
    
    @Test
    void shouldAddContent() throws Exception {
        mockMvc.perform(post("/api/v1/content")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"title\":\"Test\"}"))
                .andExpect(status().isCreated());
    }
}
```

### UI Testing (Playwright with Flutter Web)

**Module**: `playlizt-ui-tests/`  
**Technology**: Playwright (Java), JUnit 5  
**Target**: Flutter web frontend on http://localhost:4090

#### Flutter Web Testing Constraints

Flutter web uses **canvas-based rendering**, which fundamentally changes how UI testing works:

1. **Standard selectors DO NOT WORK**:
   - `page.locator("button")` - FAILS
   - `page.getByText("Login")` - FAILS
   - `page.getByRole("textbox")` - FAILS

2. **Required approach**:
   - **Primary**: Screenshot-based visual verification (MANDATORY)
   - **Interaction**: `page.evaluate()` with JavaScript
   - **Assertions**: Page URL, title, and JavaScript state
   - **Avoid**: DOM element queries

#### Test Structure

```
playlizt-ui-tests/
├── build.gradle                    # Playwright dependencies
├── src/test/java/
│   └── com/smatech/playlizt/ui/
│       ├── BasePlayliztTest.java  # Base class with screenshot utils
│       ├── PlayliztVisualE2ETest.java
│       ├── PlayliztLoginFlowE2ETest.java
│       └── PlayliztBasicE2ETest.java
├── src/test/resources/
│   └── test.properties             # Test configuration
└── src/test/output/                # Screenshot directory
    ├── auth/
    │   ├── login/
    │   └── registration/
    ├── content/
    ├── playback/
    └── visual/
```

#### Base Test Class Pattern

```java
public abstract class BasePlayliztTest {
    protected static Playwright playwright;
    protected static Browser browser;
    protected BrowserContext context;
    protected Page page;
    
    @BeforeAll
    static void launchBrowser() {
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions()
            .setHeadless(false)  // NON-HEADLESS for visual verification
            .setSlowMo(500));    // Slow motion for observation
    }
    
    protected void takeScreenshot(String category, String testName, String filename) {
        Path dir = Paths.get("src/test/output", category, testName);
        Files.createDirectories(dir);
        page.screenshot(new Page.ScreenshotOptions()
            .setPath(dir.resolve(filename)));
    }
}
```

#### Example Test (Flutter-Compatible)

```java
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class PlayliztVisualE2ETest extends BasePlayliztTest {
    
    @Test
    @Order(1)
    @DisplayName("Visual Test: Login page loads correctly")
    void visualTest01_LoginPage() {
        // Navigate
        page.navigate("http://localhost:4090");
        page.waitForLoadState(LoadState.NETWORKIDLE);
        
        // Assert page state (NOT DOM elements)
        assertThat(page.title()).contains("Playlizt");
        assertThat(page.url()).contains("localhost:4090");
        
        // PRIMARY VERIFICATION: Screenshot
        takeScreenshot("visual", "01-login-page", "01-initial-load.png");
        
        // MANUALLY INSPECT SCREENSHOT - MANDATORY
        System.out.println("✓ Screenshot captured for manual verification");
    }
    
    @Test
    @Order(2)
    @DisplayName("Visual Test: Page reload consistency")
    void visualTest02_ReloadConsistency() {
        page.navigate("http://localhost:4090");
        takeScreenshot("visual", "02-reload", "01-first-load.png");
        
        // Reload and compare
        page.reload();
        page.waitForLoadState(LoadState.NETWORKIDLE);
        takeScreenshot("visual", "02-reload", "02-after-reload.png");
        
        // Manual verification will confirm consistency
    }
}
```

#### Screenshot Verification Workflow

**CRITICAL**: Screenshots are the PRIMARY test validation method.

1. **Capture Phase**:
   - Run tests with `--rerun-tasks` flag
   - Tests execute in NON-HEADLESS mode
   - Screenshots captured at each key step
   - Output: `src/test/output/{category}/{test}/{step}-{action}.png`

2. **Verification Phase (MANDATORY)**:
   ```bash
   # List all screenshots
   find playlizt-ui-tests/src/test/output -name "*.png" | sort
   
   # Open each screenshot manually
   xdg-open playlizt-ui-tests/src/test/output/visual/01-login-page/01-initial-load.png
   ```

3. **Checklist per Screenshot**:
   - ✅ Page title correct
   - ✅ All UI elements visible (form, buttons, links)
   - ✅ Text is readable and properly formatted
   - ✅ Layout is professional and aligned
   - ✅ No rendering errors or broken elements
   - ✅ Colors and styling match design
   - ✅ Responsive design working (if applicable)

4. **Issue Classification**:
   - **Naming Problem**: Screenshot name doesn't match content → Rename
   - **Test Bug**: Test navigated wrong or timing issue → Fix test code
   - **Code Bug**: UI not rendering correctly → Fix Flutter frontend
   - **Strict Testing Gap**: Missing assertions → Add validation

5. **Fix Workflow**:
   ```bash
   # Fix the identified issue
   # Then rerun ONLY the specific test
   ./gradlew :playlizt-ui-tests:test --tests "PlayliztVisualE2ETest.visualTest01_LoginPage"
   
   # Manually verify the new screenshot
   xdg-open playlizt-ui-tests/src/test/output/visual/01-login-page/01-initial-load.png
   
   # Document the fix
   echo "Fixed: [description]" >> SCREENSHOT_VERIFICATION_COMPLETE.md
   ```

6. **Documentation**: 
   - Results logged in `SCREENSHOT_VERIFICATION_COMPLETE.md`
   - Status: PASS/FAIL for each screenshot
   - Issues found and fixes applied
   - Final sign-off with verification date

#### Running UI Tests

```bash
# Run all UI tests (NON-HEADLESS)
./gradlew :playlizt-ui-tests:test \
  -Dplaywright.headless=false \
  -Dplaywright.slowmo=500 \
  --rerun-tasks

# Run specific test class
./gradlew :playlizt-ui-tests:test \
  --tests "PlayliztVisualE2ETest" \
  -Dplaywright.headless=false

# Run single test method
./gradlew :playlizt-ui-tests:test \
  --tests "PlayliztVisualE2ETest.visualTest01_LoginPage" \
  -Dplaywright.headless=false
```

#### Prerequisites

1. Backend services running and healthy:
   ```bash
   ./playlizt-docker.sh --status
   ```

2. Flutter web app running on port 4090:
   ```bash
   curl -I http://localhost:4090
   ```

3. Playwright browsers installed:
   ```bash
   cd playlizt-ui-tests
   ./install-browsers.sh
   ```

#### Quality Standards

**Screenshot Requirements**:
- Resolution: 1920x1080 minimum
- Format: PNG (lossless)
- Clarity: Text must be readable
- Completeness: Full page or relevant section captured
- Timing: Capture after page fully stabilizes

**Test Execution**:
- Browser: Chromium (consistent rendering)
- Viewport: 1920x1080 desktop standard
- Network: Wait for NETWORKIDLE before assertions
- Slowmo: 500ms for visual observation
- Isolation: Clear browser state between tests

#### Success Criteria

- ✅ All tests execute without crashes
- ✅ All screenshots captured successfully
- ✅ Every screenshot manually opened and verified
- ✅ Visual verification log completed (SCREENSHOT_VERIFICATION_COMPLETE.md)
- ✅ All UI bugs identified and documented
- ✅ Test code issues fixed
- ✅ Backend issues tracked
- ✅ Screenshot names accurately describe content

#### Common Issues

**Issue**: `TimeoutError: waiting for locator("input")`  
**Cause**: Flutter canvas rendering - standard selectors don't work  
**Solution**: Use screenshot verification instead of element interaction

**Issue**: Tests pass but screenshots show errors  
**Cause**: Insufficient test validation  
**Solution**: Add visual verification and manual screenshot review

**Issue**: Screenshots inconsistent across runs  
**Cause**: Race conditions, timing issues  
**Solution**: Add explicit waits: `page.waitForLoadState(NETWORKIDLE)` + `waitForTimeout(2000)`

**Issue**: Backend not ready when tests run  
**Cause**: Services not fully initialized  
**Solution**: Check health endpoints before running tests with `--status`

## API Standards

### RESTful Design
**Base URL**: `/api/v1`
**Versioning**: Path-based

### Endpoints

**Authentication**:
```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh
POST /api/v1/auth/logout
```

**Content**:
```
GET    /api/v1/content
GET    /api/v1/content/{id}
POST   /api/v1/content             # authenticated user (upload)
PUT    /api/v1/content/{id}        # authenticated owner of the content
DELETE /api/v1/content/{id}        # authenticated owner of the content
GET    /api/v1/content/search
GET    /api/v1/content/categories
```

**Playback**:
```
POST /api/v1/playback/start
POST /api/v1/playback/update
POST /api/v1/playback/complete
GET  /api/v1/playback/history
GET  /api/v1/playback/continue
```

**AI**:
```
GET  /api/v1/ai/recommendations
POST /api/v1/ai/enhance
GET  /api/v1/ai/insights           # authenticated user
POST /api/v1/ai/sentiment
```

### Response Format
```json
{
  "success": true,
  "data": { "id": 1, "title": "Example" },
  "timestamp": "2025-11-24T16:32:00Z"
}
```

### Pagination
**Parameters**: `page` (0-based), `size` (max 100), `sort`
```json
{
  "content": [...],
  "page": 0,
  "size": 20,
  "totalElements": 156,
  "totalPages": 8,
  "hasNext": true
}
```

### OpenAPI Documentation
```gradle
implementation 'org.springdoc:springdoc-openapi-starter-webmvc-ui:2.6.0'
```
**Access**: `http://localhost:4080/swagger-ui.html`

## Docker & Deployment

### Standard Dockerfile
**Base Image**: `eclipse-temurin:25-jre-jammy`

```dockerfile
FROM eclipse-temurin:25-jdk-jammy AS build
WORKDIR /workspace
COPY gradlew gradle/ settings.gradle build.gradle ./
COPY playlizt-authentication/ playlizt-authentication/
RUN ./gradlew :playlizt-authentication:bootJar -x test

FROM eclipse-temurin:25-jre-jammy
RUN groupadd -r playlizt -g 1000 && \
    useradd -r -g playlizt -u 1000 -m playlizt
WORKDIR /app
COPY --from=build /workspace/playlizt-authentication/build/libs/playlizt-authentication.jar playlizt-authentication.jar
RUN mkdir -p /var/log/playlizt && chown -R playlizt:playlizt /var/log/playlizt
USER playlizt:playlizt
EXPOSE 4081
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:4081/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "playlizt-authentication.jar"]
```

### Docker Compose
```yaml
version: '3.8'

services:
  playlizt-database:
    image: postgres:17
    environment:
      POSTGRES_DB: ${PLAYLIZT_DB_NAME}
      POSTGRES_USER: ${PLAYLIZT_DB_USER}
      POSTGRES_PASSWORD: ${PLAYLIZT_DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "${PLAYLIZT_DB_PORT}:${PLAYLIZT_DB_PORT}"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${PLAYLIZT_DB_USER} -d ${PLAYLIZT_DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

  playlizt-eureka-service:
    build:
      context: .
      dockerfile: playlizt-eureka-service/Dockerfile
    ports:
      - "${PLAYLIZT_EUREKA_PORT}:${PLAYLIZT_EUREKA_PORT}"
    depends_on:
      - playlizt-database

  playlizt-authentication:
    build:
      context: .
      dockerfile: playlizt-authentication/Dockerfile
    ports:
      - "${PLAYLIZT_AUTH_PORT}:${PLAYLIZT_AUTH_PORT}"
    environment:
      - SERVER_PORT=${PLAYLIZT_AUTH_PORT}
      - SPRING_DATASOURCE_URL=jdbc:postgresql://${PLAYLIZT_DB_HOST}:${PLAYLIZT_DB_PORT}/${PLAYLIZT_DB_NAME}
      - PLAYLIZT_JWT_SECRET=${PLAYLIZT_JWT_SECRET}
      - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=${PLAYLIZT_EUREKA_URL}
    depends_on:
      - playlizt-database
      - playlizt-eureka-service

volumes:
  postgres_data:
```

## Operations

### playlizt-docker.sh Management Script

**Actions**:
```bash
./playlizt-docker.sh -r [services]      # Restart
./playlizt-docker.sh -rr [services]     # Redeploy + Restart
./playlizt-docker.sh -rrr [services]    # Rebuild + Redeploy + Restart
./playlizt-docker.sh -rrrr [services]   # Recreate + Rebuild + Redeploy + Restart
./playlizt-docker.sh -rrrrr [services]  # Redownload + Full rebuild
```

**Options**:
```bash
--rebuild-all      # Rebuild all services
--restart-all      # Restart all services
--status           # Show service status
--logs [service]   # Show logs
--test [unit|all]  # Run tests
--cleanup          # Stop and remove all
```

**Examples**:
```bash
./playlizt-docker.sh -rrr playlizt-authentication playlizt-content-api
./playlizt-docker.sh --logs --tail 200 playlizt-authentication
./playlizt-docker.sh --test unit
./playlizt-docker.sh --rebuild-all
```

### Rebuild Process
1. **Destroy**: Stop services in dependency order
2. **Rebuild**: Build artifacts via Gradle
3. **Start**: Bring up services one by one
4. **Verify**: Check health endpoints
5. **Monitor**: Review logs and metrics

### Development Workflow
```bash
# Start development
./playlizt-docker.sh --rebuild-all

# Make changes to playlizt-authentication
./playlizt-docker.sh -rrr playlizt-authentication

# Run tests
./playlizt-docker.sh --test unit

# View logs
./playlizt-docker.sh --logs -f playlizt-authentication

# Cleanup
./playlizt-docker.sh --cleanup
```

### Logging
- **Location**: `/var/log/playlizt/{service}.log`
- **Format**: Structured plain text
- **Rotation**: Daily, 7-day retention

### Health Checks
```properties
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
management.endpoint.health.probes.enabled=true
management.health.livenessState.enabled=true
management.health.readinessState.enabled=true
```

## Development Standards

### Lombok Usage (Mandatory)
```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String username;
    @ToString.Exclude
    private String passwordHash;
}
```

### DTO Mapping (MapStruct)
```java
@Mapper(componentModel = "spring")
public interface ContentMapper {
    ContentResponse toResponse(Content content);
    Content toEntity(ContentRequest request);
}
```

### Logging
```java
@Slf4j
public class ContentService {
    public Content add(ContentRequest request) {
        log.info("Adding content: title={}", request.getTitle());
        try {
            return contentRepository.save(entity);
        } catch (Exception e) {
            log.error("Failed to add content", e);
            throw e;
        }
    }
}
```

### Exception Handling
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ApiResponse.error("RESOURCE_NOT_FOUND", ex.getMessage()));
    }
}
```

## End-to-End Deployment

### 1. Credential Management
All deployment scripts rely on a centralized credentials file located at `~/gcp/credentials_playlizt`. This file contains sensitive configuration for GCP, Database, and GitHub.

**File Structure (`~/gcp/credentials_playlizt`)**:
```bash
# Google Cloud Configuration
export GCP_PROJECT_ID="playlizt-production-123"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"

# Database Configuration
export DB_USER="playlizt_admin"
export DB_PASSWORD="<STRONG_GENERATED_PASSWORD>"
export DB_NAME="playlizt"

# Application Secrets
export JWT_SECRET="<STRONG_GENERATED_SECRET>"

# GitHub Configuration
export GITHUB_REPO_URL="https://github.com/t3ratech/playlizt.git"
export GITHUB_TOKEN="ghp_YOUR_GITHUB_TOKEN"

# Local Development
export JAVA_VERSION="25"
export ANDROID_SDK_ROOT="/opt/android/sdk"
```

### 2. Deployment Scripts
The project includes automated scripts for setting up the environment from scratch, located in `playlizt-ops/scripts/`:

#### A. `playlizt-ops/scripts/setupGIT.sh`
- **Purpose**: Clones the repository using the provided GitHub token.
- **Usage**: `./playlizt-ops/scripts/setupGIT.sh`
- **Pre-requisites**: `~/gcp/credentials_playlizt` must exist.

#### B. `playlizt-ops/scripts/setupLocal.sh`
- **Purpose**: Installs all necessary development tools on a fresh Ubuntu machine.
- **Installs**:
  - Java 25 (Temurin)
  - Docker & Docker Compose
  - Terraform
  - Google Cloud SDK (via Snap)
  - Android SDK (Command Line Tools)
- **Usage**: `./playlizt-ops/scripts/setupLocal.sh` (requires sudo)

#### C. `playlizt-ops/scripts/setupGCP.sh` (Invoked via playlizt-docker.sh)
- **Purpose**: Provisions GCP infrastructure and deploys the application.
- **Actions**:
  1.  Initializes Terraform.
  2.  Creates Artifact Registry.
  3.  Builds and Pushes Docker images for all services.
  4.  Deploys Cloud Run services and Cloud SQL (Postgres 17) via Terraform.
- **Usage**: `./playlizt-docker.sh --deploy`

### 3. Terraform Infrastructure
Infrastructure as Code (IaC) is managed via Terraform in the `terraform/` directory.

- **Resources**:
  - **Cloud SQL**: PostgreSQL 17 (Production Grade)
  - **Cloud Run**: Serverless compute for microservices
  - **Artifact Registry**: Docker image storage
  - **Secret Manager**: (Optional) For storing sensitive config
- **State**: Local state (default), configure backend for production team usage.

## Success Criteria

- [x] Configuration externalized with no defaults
- [x] All services use Lombok
- [x] JAR files uniquely named
- [x] PostgreSQL 17 for production
- [x] Testcontainers for integration tests
- [x] Argon2id password hashing
- [x] Gemini AI integration (Recommendation Engine, Async Metadata Enhancer, Fallback)
- [x] Swagger API documentation
- [x] 80% test coverage
- [x] Docker containerization
- [x] playlizt-docker.sh management
- [x] Health checks enabled
- [x] Non-root containers
- [x] Rate Limiting (Redis)
- [x] Centralized File Logging
- [x] Analytics dashboard & insights
- [x] Content Upload & Storage
- [x] Profile Management

---

**Author**: Tsungai  
**Date**: 2025-11-24  
**Version**: 1.0.0  
**Copyright**: © 2025 T3raTech Solutions (Pvt) Ltd
