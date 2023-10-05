resource "google_storage_bucket" "storage_analytics_transfer_function" {
    name = "storage_analytics_transfer_function"
    location = var.location
}

resource "google_storage_bucket_object" "function_zipped" {
    name = "func.zip"
    bucket = storage_analytics_transfer_function.name
    source = "./function/"
}

resource "google_cloudfunctions_function" "function_analytics_events_transfer" {
    name = "function_analytics_events_transfer"
    runtime = "python311"
    description = "function that will trigger daily transfer of GA4 data within BQ to BQ instance used for search"
    trigger_http = 1
    https_trigger_security_level - "SECURE_ALWAYS"
    ingress_settings = "ALLOW_INTERNAL_ONLY"
    source_archive_bucket = google_storage_bucket.storage_analytics_transfer_function
    source_archive_object = google_storage_bucket_object.function_zipped
}