
#!/bin/bash

# Set the Google Cloud project ID
export TF_VAR_project_id=$(gcloud config get project)

# Set the region
export TF_VAR_region=us-central1

# Set the OpenWeatherMap API key
export TF_VAR_weather_api_key=${WEATHER_API_KEY}

# Set the OpenWeatherMap API URL
export TF_VAR_weather_api_url=https://api.openweathermap.org/data/2.5/weather

# Set the Google Cloud Storage service account
export TF_VAR_gcs_sa=$(gsutil kms serviceaccount -p rick-devops-01)

# Change to the storage-handler directory
cd duet-ai-storageservice/storage-handler

# Submit the Cloud Build job
gcloud builds submit .

# Change to the app-infra directory
cd ../../app-infra

# Initialize Terraform
terraform init

# Validate the Terraform configuration
terraform validate

# Apply the deployment
terraform apply --auto-approve

