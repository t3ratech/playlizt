# Build stage
FROM eclipse-temurin:25-jdk-jammy AS build
WORKDIR /workspace

# Copy local Gradle distribution to avoid downloading (speeds up builds)
RUN mkdir -p /opt/gradle-wrapper
COPY gradle/wrapper/gradle-9.2.1-bin.zip /opt/gradle-wrapper/

# Copy Gradle wrapper and build files
COPY gradlew .
COPY gradle gradle
COPY build.gradle .

# Override gradle-wrapper.properties to use local distribution
RUN echo 'distributionBase=GRADLE_USER_HOME' > gradle/wrapper/gradle-wrapper.properties && \
    echo 'distributionPath=wrapper/dists' >> gradle/wrapper/gradle-wrapper.properties && \
    echo 'distributionUrl=file:/opt/gradle-wrapper/gradle-9.2.1-bin.zip' >> gradle/wrapper/gradle-wrapper.properties && \
    echo 'networkTimeout=10000' >> gradle/wrapper/gradle-wrapper.properties && \
    echo 'zipStoreBase=GRADLE_USER_HOME' >> gradle/wrapper/gradle-wrapper.properties && \
    echo 'zipStorePath=wrapper/dists' >> gradle/wrapper/gradle-wrapper.properties

# Create minimal settings.gradle for single service
RUN echo "rootProject.name = 'playlizt'" > settings.gradle && \
    echo "include('api-gateway')" >> settings.gradle
COPY gradle.properties .

# Copy api-gateway source
COPY api-gateway/build.gradle.kts api-gateway/
COPY api-gateway/src api-gateway/src

# Build the application
RUN ./gradlew :api-gateway:bootJar -x test --no-daemon

# Runtime stage
FROM eclipse-temurin:25-jre-jammy

# Install curl for healthchecks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Arguments for user creation
ARG PLAYLIZT_UID=1000
ARG PLAYLIZT_GID=1000
ARG SERVER_PORT

# Create non-root user
RUN groupadd -r playlizt -g ${PLAYLIZT_GID} && \
    useradd -r -g playlizt -u ${PLAYLIZT_UID} -m playlizt

# Set working directory
WORKDIR /app

# Copy JAR from build stage
COPY --from=build /workspace/api-gateway/build/libs/api-gateway.jar api-gateway.jar

# Create log directory
RUN mkdir -p /var/log/playlizt && \
    chown -R playlizt:playlizt /var/log/playlizt /app

# Switch to non-root user
USER playlizt:playlizt

# Expose port
EXPOSE ${SERVER_PORT}

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${SERVER_PORT}/actuator/health || exit 1

# Run application
ENTRYPOINT ["java", "-jar", "api-gateway.jar"]
