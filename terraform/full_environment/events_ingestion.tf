### TO DO
### Change deletion protection to true once I'm happy with the BQ
### have just the service account - pr - read role and read role binding we can take out too
### Modularise the below codebase
### renable triggers and allow bq -> vertex ds scheduler job to provide a date

# custom role for writing ga analytics data to our bq store
resource "google_project_iam_custom_role" "analytics_write_role" {
  role_id     = "analytics_write_role"
  title       = "ga4-write-bq-permissions"
  description = "Write data to vertex schemas in bq"

  permissions = [
    "bigquery.tables.update",
    "bigquery.tables.updateData",
    "bigquery.jobs.create",
    "bigquery.datasets.get",
    "bigquery.tables.get",
    "bigquery.tables.getData"
  ]
}

# binding ga write role to ga write service account
resource "google_project_iam_binding" "analytics_write" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.analytics_write_role.id

  members = [
    google_service_account.analytics_events_pipeline.member
  ]
}

# top level dataset to store events for ingestion into vertex
resource "google_bigquery_dataset" "dataset" {
  dataset_id                 = "analytics_events_vertex"
  project                    = var.gcp_project_id
  location                   = var.gcp_region
  delete_contents_on_destroy = true
}

# ga4 'view_item_list' events get transformed and inserted into this time-partitioned search-event table defined with a vertex schema
resource "google_bigquery_table" "search-event" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = "search-event"
  project             = var.gcp_project_id
  schema              = file("./files/search-event-schema.json")
  deletion_protection = false
  time_partitioning {
    field = "eventDate"
    type  = "DAY"
  }

}

# ga4 'select_item' events get transformed and inserted into this time-partitioned search-event table defined with a vertex schema
resource "google_bigquery_table" "view-item-event" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = "view-item-event"
  project             = var.gcp_project_id
  schema              = file("./files/view-item-event-schema.json")
  deletion_protection = false
}

# bucket for ga4 bq -> vertex bq function .zip
resource "google_storage_bucket" "storage_analytics_transfer_function" {
  name     = "${var.gcp_project_id}_storage_analytics_transfer"
  location = var.gcp_region
}

# zipped storage_analytics_transfer_function into bucket
resource "google_storage_bucket_object" "analytics_transfer_function_zipped" {
  name   = "analytics_transfer_function_${data.archive_file.analytics_transfer_function.output_md5}.zip"
  bucket = google_storage_bucket.storage_analytics_transfer_function.name
  source = data.archive_file.analytics_transfer_function.output_path
}

# archive .py and requirements.txt for storage_analytics_transfer_function to zip
data "archive_file" "analytics_transfer_function" {
  type        = "zip"
  source_dir  = "${path.module}/files/analytics_transfer_function/"
  output_path = "${path.module}/files/analytics_transfer_function.zip"
}

# gen 2 function for transferring from bq - ga4 to bq - vertex events schema
### TO DO - starting with just one schema
resource "google_cloudfunctions2_function" "function_analytics_events_transfer" {
  name        = "function_analytics_events_transfer"
  description = "function that will trigger daily transfer of GA4 data within BQ to BQ instance used for search"
  location    = var.gcp_region
  build_config {
    entry_point = "function_analytics_events_transfer"
    runtime     = "python311"
    source {
      storage_source {
        bucket = google_storage_bucket.storage_analytics_transfer_function.name
        object = google_storage_bucket_object.analytics_transfer_function_zipped.name
      }
    }
  }
  service_config {
    max_instance_count    = 5
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    service_account_email = google_service_account.analytics_events_pipeline.email
    environment_variables = {
      PROJECT_NAME           = var.gcp_project_id,
      DATASET_NAME           = google_bigquery_dataset.dataset.dataset_id
      ANALYTICS_PROJECT_NAME = var.gcp_analytics_project_id
      BQ_LOCATION            = var.gcp_region
    }
  }
}

# service account to trigger the function
resource "google_service_account" "trigger_function" {
  account_id   = "ga4-to-bq-vertex-transfer"
  display_name = "ga4-to-bq-vertex-transfer"
  project      = var.gcp_project_id
}

# custom role for triggering transfer function
resource "google_project_iam_custom_role" "trigger_function_role" {
  role_id     = "trigger_function_role"
  title       = "scheduler_ga4_to_bq_vertex_transfer-permissions"
  description = "Trigger the function for BQ GA4 -> BQ Vertex Schema data"

  permissions = [
    "cloudfunctions.functions.invoke",
    "run.jobs.run",
    "run.routes.invoke"
  ]
}

# binding role to trigger function to service account for the function
resource "google_project_iam_binding" "trigger_function" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.trigger_function_role.id

  members = [
    google_service_account.trigger_function.member
  ]
}

# scheduler resource that will transfer data at midday
resource "google_cloud_scheduler_job" "daily_transfer_view_item" {
  name        = "transfer_ga4_to_bq_view_item"
  description = "transfer view-item ga4 bq data to vertex schemas within bq"
  schedule    = "0 12 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.function_analytics_events_transfer.url
    body        = base64encode("{ \"event_type\" : \"view-item\", \"date\" : null}")
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      service_account_email = google_service_account.trigger_function.email
      audience              = google_cloudfunctions2_function.function_analytics_events_transfer.url
    }
  }
}

# scheduler resource that will transfer data at midday
resource "google_cloud_scheduler_job" "daily_transfer_search" {
  name        = "transfer_ga4_to_bq_search"
  description = "transfer search ga4 bq data to vertex schemas within bq"
  schedule    = "0 12 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.function_analytics_events_transfer.url
    body        = base64encode("{ \"event_type\" : \"search\", \"date\" : null}")
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      service_account_email = google_service_account.trigger_function.email
      audience              = google_cloudfunctions2_function.function_analytics_events_transfer.url
    }
  }
}

# custom role for writing vertex analytics data to vertex datastore
resource "google_project_iam_custom_role" "vertex_upload_role" {
  role_id     = "vertex_upload_role"
  title       = "bq-write-vertex-permissions"
  description = "Write data to vertex datastore from bq"

  permissions = [
    "bigquery.jobs.create",
    "bigquery.datasets.get",
    "bigquery.tables.get",
    "bigquery.tables.getData",
    "discoveryengine.userEvents.import",
    "discoveryengine.userEvents.create"
  ]
}

# binding ga write role to ga write service account
resource "google_project_iam_binding" "vertex_datastore_write" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.vertex_upload_role.id

  members = [
    google_service_account.analytics_events_pipeline.member
  ]
}

# bucket for vertex bq -> vertex datastore function .zip
resource "google_storage_bucket" "import_user_events_vertex_function" {
  name     = "${var.gcp_project_id}_import_user_events_vertex"
  location = var.gcp_region
}

# zipped import_user_events_vertex function into bucket
resource "google_storage_bucket_object" "import_user_events_vertex_function_zipped" {
  name   = "import_user_events_vertex_function_${data.archive_file.import_user_events_vertex_function.output_md5}.zip"
  bucket = google_storage_bucket.import_user_events_vertex_function.name
  source = data.archive_file.import_user_events_vertex_function.output_path
}

# archive .py and requirements.txt for import_user_events_vertex to zip
data "archive_file" "import_user_events_vertex_function" {
  type        = "zip"
  source_dir  = "${path.module}/files/vertex_events_push/"
  output_path = "${path.module}/files/vertex_events_push.zip"
}


# gen 2 function for transferring from bq - vertex events schema to vertex engine
resource "google_cloudfunctions2_function" "import_user_events_vertex" {
  name        = "import_user_events_vertex"
  description = "function that will trigger daily to transfer of ga4 events data in vertex schema in bq to vertex"
  location    = var.gcp_region
  build_config {
    entry_point = "import_user_events_vertex"
    runtime     = "python311"
    source {
      storage_source {
        bucket = google_storage_bucket.import_user_events_vertex_function.name
        object = google_storage_bucket_object.import_user_events_vertex_function_zipped.name
      }
    }
  }
  service_config {
    max_instance_count    = 5
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    service_account_email = google_service_account.analytics_events_pipeline.email
  }
}

# scheduler resource that will transfer `search` vertex bq data - > vertex datastore at 1230
resource "google_cloud_scheduler_job" "daily_transfer_bq_search_to_vertex" {
  name        = "transfer_search_event_to_vertex_datastore"
  description = "transfer search vertex bq data to vertex datastore"
  schedule    = "30 12 * * *"
  time_zone   = "Europe/London"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.import_user_events_vertex.url
    body        = base64encode("{ \"event_type\" : \"search\", \"date\" : null}") 
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      service_account_email = google_service_account.trigger_function.email
      audience              = google_cloudfunctions2_function.import_user_events_vertex.url
    }
  }
}

# # scheduler resource that will transfer `view-item` vertex bq data - > vertex datastore at 1230
# resource "google_cloud_scheduler_job" "daily_transfer_bq_view_item_to_vertex" {
#   name        = "transfer_view_item_to_vertex_datastore"
#   description = "transfer view item vertex bq data to vertex datastore"
#   schedule    = "30 12 * * *"
#   time_zone   = "Europe/London"

#   http_target {
#     http_method = "POST"
#     uri         = google_cloudfunctions2_function.import_user_events_vertex.url
#     body        = base64encode("{ \"event_type\" : \"view-item\"}") 
#     headers = {
#       "Content-Type" = "application/json"
#     }
#     oidc_token {
#       service_account_email = google_service_account.trigger_function.email
#       audience              = google_cloudfunctions2_function.import_user_events_vertex.url
#     }
#   }
# }
