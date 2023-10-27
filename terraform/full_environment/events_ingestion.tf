# service account for transferring data
resource "google_service_account" "analytics_transfer" {
  account_id   = "ga4-transfer-bq"
  display_name = "ga4-transfer-bq"
  project      = var.gcp_project_id
}

# custom role for analytics transfer
resource "google_project_iam_custom_role" "analytics_transfer_role" {
  role_id     = "analytics_transfer_role"
  title       = "ga4-transfer-bq-permissions"
  description = "Enables read-only access to the search-api-v2 Rails app"

  permissions = [
    "bigquery.datasets.get",
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "bigquery.tables.update",
    "bigquery.tables.updateData",
    "bigquery.jobs.create"
  ]
}

# binding role to service account
resource "google_project_iam_binding" "analytics_transfer" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.analytics_transfer_role.id

  members = [
    google_service_account.analytics_transfer.member
  ]
}

# top level dataset to store events for ingestion into vertex
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "analytics_events_vertex"
  project = var.gcp_project_id
}

# ga4 'view_item_list' events get transformed and inserted into this time-partitioned search-event table defined with a vertex schema 
resource "google_bigquery_table" "search-event" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id = "search-event"
  project = var.gcp_project_id
  schema = file("./files/search-event-schema.txt")
  deletion_protection = true
  time_partitioning {
    field = "eventTime"
    type = "DAY"
  }

}

# ga4 'select_item' events get transformed and inserted into this time-partitioned search-event table defined with a vertex schema 
resource "google_bigquery_table" "view-item-event" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id = "view-item-event"
  project = var.gcp_project_id
  schema = file("./bq_schemas/view-item-event-schema.txt")
  deletion_protection = false 
  time_partitioning {
    field = "eventTime"
    type = "DAY"
    }
}

# bucket for function .zip
resource "google_storage_bucket" "storage_analytics_transfer_function" {
    name = "storage_analytics_transfer_function"
    location = var.location
}

# zipped function into bucket
resource "google_storage_bucket_object" "function_zipped" {
    name = "func.zip"
    bucket = google_storage_bucket.storage_analytics_transfer_function.name
    source = data.archive_file.init.output_path
}

# archive .py and requirements.txt to zip
data "archive_file" "init" {
  type        = "zip"
  source_file = "./files/function/"
  output_path = "./files/init.zip"
}

# gen 2 function for transferring from bq - ga4 to bq - vertex events schema
### TO DO - starting with just one schema
resource "google_cloudfunctions2_function" "function_analytics_events_transfer" {
    name = "function_analytics_events_transfer"
    description = "function that will trigger daily transfer of GA4 data within BQ to BQ instance used for search"
    location = ""
    build_config {
        runtime = "python311"
    }
    source {
        storage_source {
            bucket = google_storage_bucket.storage_analytics_transfer_function.name
            object = google_storage_bucket_object.function_zipped.name
        }
    }

    service_config {
        max_instance_count = 5,
        vpc_connector_egress_setting = "ALL_TRAFFIC",
        ingress_setting = "ALLOW_INTERNAL_ONLY"
    }
}

# 
resource "google_service_account" "trigger_function" {
  account_id   = "scheduler_ga4_to_bq_vertex_transfer"
  display_name = "scheduler_ga4_to_bq_vertex_transfer"
  project      = var.gcp_project_id
}

# custom role for triggering transfer function
resource "google_project_iam_custom_role" "trigger_function_role" {
  role_id     = "trigger_function_role"
  title       = "scheduler_ga4_to_bq_vertex_transfer-permissions"
  description = "Enables read-only access to the search-api-v2 Rails app"

  permissions = [
    "bigquery.datasets.get"
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
    name = 
    description = 
    schedule = 
    time_zone = 

    http_target {
        http_method = "POST"
        uri = 
        body = 
        headers = {
             "Content-Type" = "application/json"
        }
    }
}
