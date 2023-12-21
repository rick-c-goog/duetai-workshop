FROM python:3.11-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    g++ \
    libopenblas-dev \
    liblapack-dev \
    wget

# Copy the app code to the container image
WORKDIR /app
COPY . .

# Run the app on container startup
CMD ["python", "app.py"]
