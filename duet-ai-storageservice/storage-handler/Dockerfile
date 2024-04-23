FROM maven:3-eclipse-temurin-17-alpine as builder

# Copy local code to the container image.
WORKDIR /app
COPY pom.xml .
COPY src ./src

# Build a release artifact.
RUN mvn package -DskipTests

# Use Eclipse Temurin for base image.
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM eclipse-temurin:17.0.9_9-jre-alpine

# Copy the jar to the production image from the builder stage.
COPY --from=builder /app/target/audit-storage-*.jar /audit-storage.jar

RUN curl -L -O https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.32.0/opentelemetry-javaagent.jar
# Run the web service on container startup.
RUN export JAVA_TOOL_OPTIONS="-javaagent:./opentelemetry-javaagent.jar -Dotel.exporter.otlp.protocol=grpc" \
  OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4317 \
  OTEL_TRACES_EXPORTER=otlp \
  OTEL_METRICS_EXPORTER=otlp \
  OTEL_LOGS_EXPORTER=otlp \
  OTEL_SERVICE_NAME=duet-ai-storageservice

CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/audit-storage.jar"]

# [END eventarc_audit_storage_dockerfile]
