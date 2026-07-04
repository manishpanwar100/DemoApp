# ===========================
# Stage 1: Build Application
# ===========================
FROM gradle:8-jdk21 AS build

WORKDIR /app

# Copy only build configuration first (for caching)
COPY build.gradle.kts settings.gradle.kts gradlew ./
COPY gradle ./gradle

RUN ./gradlew dependencies --no-daemon || return 0

# Copy the rest of the project files
COPY . .

# Build the Spring Boot JAR
RUN ./gradlew clean build -x test --no-daemon


# ===========================
# Stage 2: Run Application
# ===========================
FROM eclipse-temurin:21-jdk

WORKDIR /app

# Copy built JAR from previous stage
COPY --from=build /app/build/libs/*.jar app.jar

# Define environment variables for MySQL (can override from docker run / compose)
ENV SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/db_roomlocus
ENV SPRING_DATASOURCE_USERNAME=my_admin
ENV SPRING_DATASOURCE_PASSWORD=my_password
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update

# Copy wait-for script and use it as entrypoint so the app waits for MySQL readiness
COPY wait-for-mysql.sh /wait-for-mysql.sh
RUN chmod +x /wait-for-mysql.sh

EXPOSE 8082



#ENTRYPOINT ["/bin/bash","wait-for-mysql.sh"]
# Correct way to start Spring Boot app
ENTRYPOINT ["java", "-jar", "app.jar"]