resource "google_service_account" "default" {
  account_id   = "my-service-account"
  display_name = "My Service Account"
}

resource "google_service_account_iam_binding" "default" {
  role    = "roles/run.invoker"
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_service_account_iam_binding" "bigquery_read_write" {
  role    = "roles/bigquery.dataOwner"
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_service_account_iam_binding" "cloud_function_invoker" {
  role    = "roles/cloudfunctions.invoker"
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_service_account_iam_binding" "cloud_run_invoker" {
  role    = "roles/run.invoker"
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_service_account_iam_binding" "cloud_storage_read_write" {
  role    = "roles/storage.objectAdmin"
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_service_account_iam_binding" "pubsub_read_write" {
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_bigquery_dataset" "default" {
  dataset_id = "my-dataset"
}

resource "google_bigquery_table" "default" {
  table_id   = "my-table"
  dataset_id = google_bigquery_dataset.default.dataset_id
  schema {
    fields {
      name  = "name"
      type  = "STRING"
      mode = "REQUIRED"
    }
    fields {
      name  = "age"
      type  = "INTEGER"
      mode = "REQUIRED"
    }
  }
}

resource "google_storage_bucket" "default" {
  name = "sample_data"
}

resource "google_cloud_scheduler_job" "default" {
  name         = "weather_client"
  description  = "A job that runs every hour"
  schedule     = "0 * * * *"
  time_zone    = "America/New_York"
  attempt_deadline = "3600s"
  uri          = "https://us-central1-PROJECT_ID.cloudfunctions.net/weather_client"
  http_method  = "POST"
  oidc_token {
    service_account_email = google_service_account.default.email
    audience             = "https://us-central1-PROJECT_ID.cloudfunctions.net/weather_client"
  }
}

resource "google_eventarc_trigger" "default" {
  name        = "data_ingestion"
  description = "A trigger that runs when a file is uploaded to a Cloud Storage bucket"
  event_filters {
    type = "google.cloud.storage.object.v1.finalized"
  }
  transport {
    pubsub {
      topic = google_pubsub_topic.default.name
    }
  }
  service_account_email = google_service_account.default.email
}

resource "google_pubsub_topic" "default" {
  name = "data_ingestion"
}

resource "google_cloud_run_service" "default" {
  name     = "data_ingestion"
  location = "us-central1"
  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/hello"
      }
    }
  }
}

resource "google_project_service" "all" {
  provider = google-beta
  service  = [
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "bigquery.googleapis.com",
    "cloudscheduler.googleapis.com",
    "eventarc.googleapis.com",
    "storage.googleapis.com",
  ]
}
