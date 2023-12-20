FROM eclipse-temurin:17-jre-alpine

# Copy the application's dependencies from the local Maven repository.
COPY target/duet-ai-dataservice-1.0-SNAPSHOT.jar /app/duet-ai-dataservice.jar

# Create a user and group for the application to run as.
RUN useradd -u 1000 -g 1000 app

# Set the application's home directory.
RUN mkdir -p /app/home
RUN chown app:app /app/home
RUN chsh -s /bin/bash app

# Set the application's permissions.
RUN chmod 755 /app/duet-ai-dataservice.jar
RUN chown app:app /app/duet-ai-dataservice.jar

# Run the application as the app user.
CMD ["/bin/bash", "-c", "java -jar /app/duet-ai-dataservice.jar"]
