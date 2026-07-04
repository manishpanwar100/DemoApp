# ===========================
# Stage 1: Build Application
# ===========================
FROM gradle:8-jdk21 AS build

WORKDIR /app

# Copy Gradle configuration first (improves Docker layer caching)
COPY build.gradle.kts settings.gradle.kts gradlew ./
COPY gradle ./gradle

# Download dependencies
RUN ./gradlew dependencies --no-daemon || true

# Copy application source
COPY . .

# Build the Spring Boot JAR (skip tests)
RUN ./gradlew clean build -x test --no-daemon


# ===========================
# Stage 2: Run Application
# ===========================
FROM eclipse-temurin:21-jdk

WORKDIR /app

# Copy the built JAR from the build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Default environment variables (can be overridden)
ENV SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/db_roomlocus
ENV SPRING_DATASOURCE_USERNAME=my_admin
ENV SPRING_DATASOURCE_PASSWORD=my_password
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update

# Expose application port
EXPOSE 8082

# Start the Spring Boot application
ENTRYPOINT ["java", "-jar", "app.jar"]