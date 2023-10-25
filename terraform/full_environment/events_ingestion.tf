### TO DO
### Change deletion protection to true once I'm happy with the BQ

# service account for writing ga analytics data to our bq store 
resource "google_service_account" "analytics_write" {
  account_id   = "ga4-write-bq"
  display_name = "ga4-write-bq"
  project      = var.gcp_project_id
}

# custom role for writing ga analytics data to our bq store 
resource "google_project_iam_custom_role" "analytics_write_role" {
  role_id     = "analytics_write_role"
  title       = "ga4-write-bq-permissions"
  description = "Write data to vertex schemas in bq"

  permissions = [
    "bigquery.tables.update",
    "bigquery.tables.updateData",
    "bigquery.jobs.create"
  ]
}

# binding ga write role to ga write service account
resource "google_project_iam_binding" "analytics_write" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.analytics_write_role.id

  members = [
    google_service_account.analytics_write.member
  ]
}

data "google_project" "analytics_project" {
  project_id = var.gcp_analytics_project_id
}

# service account for reading ga4 data
resource "google_service_account" "analytics_read" {
  account_id   = "ga4-read-bq"
  display_name = "ga4-read-bq"
  project      = data.google_project.analytics_project.project_id
}

# custom role for analytics read
resource "google_project_iam_custom_role" "analytics_read_role" {
  role_id     = "analytics_read_role"
  title       = "ga4-read-bq-permissions"
  description = "Read source ga4 bq event data"

  permissions = [
    "bigquery.datasets.get",
    "bigquery.tables.get",
    "bigquery.tables.getData"
  ]
}

# binding role to service account
resource "google_project_iam_binding" "analytics_read" {
  project = "GA4-Analytics"
  role    = google_project_iam_custom_role.analytics_read_role.id

  members = [
    google_service_account.analytics_read.member
  ]
}

###
# top level dataset to store events for ingestion into vertex
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "analytics_events_vertex"
  project    = var.gcp_project_id
}

# ga4 'view_item_list' events get transformed and inserted into this time-partitioned search-event table defined with a vertex schema 
resource "google_bigquery_table" "search-event" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = "search-event"
  project             = var.gcp_project_id
  schema              = jsondecode(file("./files/search-event-schema.json"))
  deletion_protection = false
  time_partitioning {
    field = "eventTime"
    type  = "DAY"
  }

}

# ga4 'select_item' events get transformed and inserted into this time-partitioned search-event table defined with a vertex schema 
resource "google_bigquery_table" "view-item-event" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = "view-item-event"
  project             = var.gcp_project_id
  schema              = jsondecode(file("./files/view-item-event-schema.json"))
  deletion_protection = false
  time_partitioning {
    field = "eventTime"
    type  = "DAY"
  }
}

# bucket for function .zip
resource "google_storage_bucket" "storage_analytics_transfer_function" {
  name     = "storage_analytics_transfer_function"
  location = var.gcp_region
}

# zipped function into bucket
resource "google_storage_bucket_object" "analytics_transfer_function_zipped" {
  name   = "analytics_transfer_function.zip"
  bucket = google_storage_bucket.storage_analytics_transfer_function.name
  source = data.archive_file.analytics_transfer_function.output_path
}

# archive .py and requirements.txt to zip
data "archive_file" "analytics_transfer_function" {
  type        = "zip"
  source_dir  = "${path.module}/files/function/"
  output_path = "${path.module}/files/analytics_transfer_function.zip"
}

# gen 2 function for transferring from bq - ga4 to bq - vertex events schema
### TO DO - starting with just one schema
resource "google_cloudfunctions2_function" "function_analytics_events_transfer" {
  name        = "function_analytics_events_transfer"
  description = "function that will trigger daily transfer of GA4 data within BQ to BQ instance used for search"
  location    = var.gcp_region
  build_config {
    runtime = "python311"
    source {
      storage_source {
        bucket = google_storage_bucket.storage_analytics_transfer_function.name
        object = google_storage_bucket_object.analytics_transfer_function_zipped.name
      }
    }
    environment_variables = {
      project_name = var.gcp_project_id,
      dataset_name = google_bigquery_dataset.dataset.dataset_id
    }
  }
  service_config {
    max_instance_count            = 5
    vpc_connector_egress_settings = "ALL_TRAFFIC"
    ingress_settings              = "ALLOW_INTERNAL_ONLY"
  }
}

# 
resource "google_service_account" "trigger_function" {
  account_id   = "ga4-to-vertex-transfer"
  display_name = "ga4_to_bq_vertex_transfer"
  project      = var.gcp_project_id
}

# custom role for triggering transfer function
resource "google_project_iam_custom_role" "trigger_function_role" {
  role_id     = "trigger_function_role"
  title       = "scheduler_ga4_to_bq_vertex_transfer-permissions"
  description = "Enables read-only access to the search-api-v2 Rails app"

  permissions = [
    "cloudfunctions.functions.invoke"
  ]
}

# binding role to service account
resource "google_project_iam_binding" "trigger_function" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.trigger_function_role.id

  members = [
    google_service_account.trigger_function.member
  ]
}

#
resource "google_cloud_scheduler_job" "daily_transfer" {
  name        = "transfer_ga4_to_bq"
  description = "transfer ga4 bq data to vertex schemas within bq"
  schedule    = "0 12 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.function_analytics_events_transfer.url
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      service_account_email = google_service_account.trigger_function.email
    }
  }
}
