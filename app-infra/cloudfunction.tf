/******************************************
6. Create Weather cloud functions
 *****************************************/
resource "google_storage_bucket" "function_bucket" {
    name     = "${var.project_id}-function"
    location = var.region
    uniform_bucket_level_access       = true
    force_destroy                     = true
}


data "archive_file" "weather-client_source" {
    type        = "zip"
    source_dir  = "../weather-client"
    output_path = "tmp/weather_function.zip"
}


# Add source code zip to the Cloud Function's bucket
resource "google_storage_bucket_object" "weather-client_zip" {
    source       = data.archive_file.weather_client_source.output_path
    content_type = "application/zip"

    # Append to the MD5 checksum of the files's content
    # to force the zip to be updated as soon as a change occurs
    name         = "src-${data.archive_file.weather-client_source.output_md5}.zip"
    bucket       = google_storage_bucket.function_bucket.name

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on   = [
        google_storage_bucket.function_bucket,  # declared in `storage.tf`
        data.archive_file.weather-client_source
    ]
}



# Create the Cloud function triggered by a `Finalize` event on the bucket
resource "google_cloudfunctions_function" "weather-client_function" {
    name                  = "weather-data-to-gcs"
    runtime               = "python39"  # of course changeable

    # Get the source code of the cloud function as a Zip compression
    source_archive_bucket = google_storage_bucket.function_bucket.name
    source_archive_object = google_storage_bucket_object.weather-client_zip.name

    # Must match the function name in the cloud function `main.py` source code
    entry_point           = "weather_to_gcs"
    
    # 
    event_trigger {
      event_type= "google.pubsub.topic.publish"
      resource= "${local.cron_topic}"
      #service= "pubsub.googleapis.com"
   }
   environment_variables = {
    API_KEY = var.weather_api_key
    BUCKET_NAME = google_storage_bucket.data_storage_bucket.name
    API_URL=var.weather_api_url
   }

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on            = [
        google_storage_bucket.function_bucket,  # declared in `storage.tf`
        google_storage_bucket_object.weather-client_zip
    ]
}
