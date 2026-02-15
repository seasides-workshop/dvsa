# Build stage
FROM gradle:9.2.1-jdk17 AS build

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG UNPOPULAR_REPO_URL=http://localhost:8082
ARG UNPOPULAR_REPO_USERNAME=admin
ARG UNPOPULAR_REPO_PASSWORD=admin123
ARG NEXUS_ALLOW_INSECURE=false
ARG CACHE_BUST=1

# Copy Gradle wrapper and configuration files
COPY gradle ./gradle
COPY gradlew ./
COPY build.gradle settings.gradle ./

# Make gradlew executable
RUN chmod +x ./gradlew

RUN echo "unpopularRepoUrl=${UNPOPULAR_REPO_URL}" > gradle.properties

# Use CACHE_BUST to ensure dependencies are always fetched from Nexus
RUN echo "CACHE_BUST=${CACHE_BUST}" && \
    for i in 1 2 3 4 5 6 7 8 9 10 11 12; do \
        if curl -f -s --connect-timeout 5 "${UNPOPULAR_REPO_URL}/" > /dev/null 2>&1; then \
            ./gradlew dependencies --refresh-dependencies --no-daemon && break; \
        fi; \
        sleep 5; \
    done || ./gradlew dependencies --refresh-dependencies --no-daemon

# Copy source code
COPY src ./src

# Build the application
RUN ./gradlew build --refresh-dependencies --no-daemon -x test

# Runtime stage
FROM eclipse-temurin:17-jre

# Install curl for healthchecks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Expose the application port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

