
export TF_VAR_project_id=$(gcloud config get project)
export TF_VAR_region=us-west1
export TF_VAR_weather_api_key=${WEATHER_API_KEY}
export TF_VAR_weather_api_url=https://api.openweathermap.org/data/2.5/weather

export TF_VAR_gcs_sa=$(gsutil kms serviceaccount -p rick-devops-01)
terraform init

# Validate the Terraform configuration
terraform validate

# Apply the deployment
terraform apply --auto-approve