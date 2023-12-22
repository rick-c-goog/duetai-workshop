
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

resource "time_sleep" "sleep_after_activate_service_apis" {
  create_duration = "60s"

  depends_on = [
    module.activate_service_apis
  ]
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

resource "google_storage_bucket" "data_bucket" {
  name                              = "${var.project_id}-data_bucket"
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
  name        = "cron-weather-client-job"
  description = "weather client job"
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
  account_id   = "duetai-demo"
  display_name = "My Service Account"
}

resource "google_service_account_iam_binding" "default" {
  role    = "roles/run.invoker"
  service_account_id = google_service_account.default.account_id
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_service_account_iam_binding" "bigquery_read_write" {
  role    = "roles/bigquery.dataOwner"
  service_account_id = google_service_account.default.account_id
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_service_account_iam_binding" "cloud_function_invoker" {
  role    = "roles/cloudfunctions.invoker"
  members = ["serviceAccount:${google_service_account.default.email}"]
  service_account_id = google_service_account.default.account_id
}

resource "google_service_account_iam_binding" "cloud_run_invoker" {
  role    = "roles/run.invoker"
  members = ["serviceAccount:${google_service_account.default.email}"]
}

resource "google_service_account_iam_binding" "cloud_storage_read_write" {
  role    = "roles/storage.objectAdmin"
  members = ["serviceAccount:${google_service_account.default.email}"]
  service_account_id = google_service_account.default.account_id
}

resource "google_service_account_iam_binding" "pubsub_read_write" {
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${google_service_account.default.email}"]
  service_account_id = google_service_account.default.account_id
}


/******************************************
7. Create BigQuery Dataset
 *****************************************/

resource "google_bigquery_dataset" "weather_dataset" {
  dataset_id                  = "weather"
  friendly_name               = "weather_dataset"
  description                 = "This is a weather dataset"
  location                    = var.region
  default_table_expiration_ms = 604800000

  labels = {
    env = "default"
  }

}

resource "google_cloud_scheduler_job" "default" {
  name         = "weather_client"
  description  = "A job that runs every hour"
  schedule     = "0 * * * *"
  time_zone    = "America/New_York"
  attempt_deadline = "3600s"
  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.scheduler_topic.id
    data       = base64encode("test")
  }
}


resource "google_eventarc_trigger" "default" {
  name        = "data_ingestion"
  description = "A trigger that runs when a file is uploaded to a Cloud Storage bucket"
  event_filters {
    type = "google.cloud.storage.object.v1.finalized"
    bucket = google_storage_bucket.data_bucket.name
  }
  
  service_account_email = google_service_account.default.email
  destination {
    cloud_run {
      service = google_cloud_run_service.data-ingestion.name
      region  = google_cloud_run_service.data-ingestion.location
    }
  }
}

resource "google_cloud_run_service" "data-ingestion" {
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
