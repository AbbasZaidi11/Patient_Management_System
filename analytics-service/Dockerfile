# =======================================================
# WHY TWO STAGES?
# Stage 1 (builder) compiles the code with Maven + JDK.
# Stage 2 (runner)  only runs the JAR with a slim JRE.
# The final image contains NO Maven, NO compiler, NO source
# code — just the JAR. This keeps the image small and secure.
# =======================================================

# -------------------------------------------------------
# STAGE 1 — BUILD
# This image ships both Maven and Java 21 so we can compile.
# 'AS builder' gives this stage a name we reference below.
# -------------------------------------------------------
FROM maven:3.9.9-eclipse-temurin-21 AS builder

# All subsequent commands run inside /app inside the container.
WORKDIR /app

# Copy ONLY the pom.xml first (not the source code yet).
# Docker caches each line as a layer. If source code changes
# but the pom.xml doesn't, Docker reuses the cached
# dependency-download layer and skips the slow download.
COPY pom.xml .

# Download every dependency declared in pom.xml into the
# local Maven cache inside this image layer.
# -B = non-interactive (batch) mode for cleaner logs.
# This layer is cached until pom.xml changes.
RUN mvn dependency:go-offline -B

# NOW copy the source code. Intentionally done after the
# dependency download — changing source files won't bust
# the expensive download cache layer above.
COPY src ./src

# Compile and package into a fat JAR (includes all deps).
RUN mvn clean package

# -------------------------------------------------------
# STAGE 2 — RUNTIME
# Much smaller image — only the Java runtime, no build tools.
# -------------------------------------------------------
FROM eclipse-temurin:21-jre AS runner

WORKDIR /app

# Pull ONLY the compiled JAR out of the builder stage.
# Nothing else (source, Maven cache) ends up in this image.
COPY --from=builder ./app/target/analytics-service-0.0.1-SNAPSHOT.jar ./app.jar

# Document that this service listens on port 4002.
# (The actual port mapping is done in docker-compose.yml)
EXPOSE 4002

# Command that runs when the container starts.
ENTRYPOINT ["java","-jar","app.jar"]
