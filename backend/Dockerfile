# ===== Stage 1: Build =====
FROM gradle:8.7-jdk17 AS builder

WORKDIR /build

# Copy gradle files first for better layer caching
COPY settings.gradle ./
COPY build.gradle ./
# Download dependencies (cache layer)
RUN gradle dependencies --no-daemon || true

# Copy source and build
COPY src ./src
COPY gradle ./gradle
COPY gradlew ./
RUN chmod +x gradlew && ./gradlew bootJar --no-daemon -x test

# ===== Stage 2: Runtime =====
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="turtlecare-team"
LABEL description="TurtleCare Backend API"

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Copy the built jar from builder stage
COPY --from=builder /build/build/libs/*.jar app.jar

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 8080

# JVM tuning for containerized environment
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+UseStringDeduplication"

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
