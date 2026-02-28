# -------------------------------
# STAGE 1: BUILD STAGE
# -------------------------------

#Git push
#↓
#CI builds image using THIS file
#↓
#Image stored in ECR/DockerHub
#↓
#Production pulls image
#↓
#Container runs




# Use official Maven image with JDK 21 to build the project
# "AS builder" gives this stage a name so we can reference it later
FROM maven:3.9.9-eclipse-temurin-21 AS builder

# Set working directory inside the container
# All following commands run inside /app
WORKDIR /app

# Copy only pom.xml first
# This is done separately to leverage Docker layer caching.
# If dependencies don’t change, Docker won’t re-download them.
COPY pom.xml .

# Download all dependencies defined in pom.xml
# -B = batch mode (non-interactive, cleaner logs)
RUN mvn dependency:go-offline -B

# Now copy the actual source code
COPY src ./src

# Build the project and generate the .jar file
# "clean" removes old builds
# "package" compiles and creates jar in /app/target
RUN mvn clean package



# -------------------------------
# STAGE 2: RUNTIME STAGE
# -------------------------------

# Use a smaller JDK image for running the app
# No Maven needed in production
FROM eclipse-temurin:21-jre AS runner

# Set working directory for runtime container
WORKDIR /app

# Copy only the generated JAR from the builder stage
# We DO NOT copy source code or Maven
# This keeps final image smaller and more secure
COPY --from=builder /app/target/*.jar ./app.jar

# Tell Docker the app runs on port 4000
# (This does NOT publish the port — just documentation)
EXPOSE 4000

# Command that runs when container starts
# Equivalent to: java -jar app.jar
ENTRYPOINT ["java","-jar","app.jar"]