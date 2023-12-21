
/******************************************
1. Project Services Configuration
 *****************************************/
module "activate_service_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                  = var.project_id
  enable_apis                 = true

  activate_apis = [
    "orgpolicy.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudbuild.googleapis.com"
  ]

  disable_services_on_destroy = false
  
}


/******************************************
2. Project-scoped Org Policy Relaxing
*****************************************/

module "org_policy_allow_ingress_settings" {
source = "terraform-google-modules/org-policy/google"
policy_for = "project"
project_id = var.project_id
constraint = "constraints/cloudfunctions.allowedIngressSettings"
policy_type = "list"
enforce = false
allow= ["IngressSettings.ALLOW_ALL"]
depends_on = [
time_sleep.sleep_after_activate_service_apis
]
}

module "org_policy_allow_domain_membership" {
source = "terraform-google-modules/org-policy/google"
policy_for = "project"
project_id = var.project_id
constraint = "constraints/iam.allowedPolicyMemberDomains"
policy_type = "list"
enforce = false
depends_on = [
time_sleep.sleep_after_activate_service_apis
]
}

/******************************************
3. Create 2 Storge Buckets
 *****************************************/

resource "google_storage_bucket" "upload_bucket" {
  name                              = "${var.project_id}-upload_bucket"
  location                          = var.region
  uniform_bucket_level_access       = true
  force_destroy                     = true
}

resource "google_storage_bucket" "function_bucket" {
  name                              = "${var.project_id}-function_bucket"
  location                          = var.region
  uniform_bucket_level_access       = true
  force_destroy                     = true
}


/******************************************
4. Create a pubsub topic
 *****************************************/
resource "google_pubsub_topic" "scheduler_topic" {
  name = "${var.project_id}-cron_topic"

  labels = {
    job = "cron-job"
  }

  message_retention_duration = "86600s"
}

/******************************************
5.Create a cloud scheduler
 *****************************************/
resource "google_cloud_scheduler_job" "job" {
  name        = "cron-bq-export-job"
  description = "bq export job"
  schedule    = "0 12 * * SUN"
  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.scheduler_topic.id
    data       = base64encode("test")
  }
}

/******************************************
6.Service account and IAM permissions
 *****************************************/
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
  dataset_id = "weather-dataset"
}

resource "google_bigquery_table" "default" {
  table_id   = "weather-table"
  dataset_id = google_bigquery_dataset.default.dataset_id
  schema {
    fields {
      name  = "latitude"
      type  = "double"
      mode = "REQUIRED"
    }
    fields {
      name  = "longitude"
      type  = "double"
      mode = "REQUIRED"
    }
    fields {
      name  = "weathercode"
      type  = "integer"
      mode = "REQUIRED"
    }
    fields {
      name  = "temperature"
      type  = "double"
      mode = "REQUIRED"
    }
    fields {
      name  = "windspeed"
      type  = "integer"
      mode = "REQUIRED"
    }
    fields {
      name  = "winddirection"
      type  = double"
      mode = "REQUIRED"
    }
    fields {
      name  = "humidity"
      type  = "double"
      mode = "REQUIRED"
    }
    fields {
      name  = "time"
      type  = "datetime"
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
