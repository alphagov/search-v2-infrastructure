resource "google_bigquery_dataset" "evaluator" {
  dataset_id                 = "search_v2_evaluator"
  location                   = var.gcp_region
  delete_contents_on_destroy = true
}

resource "google_bigquery_table" "evaluator_ratings" {
  dataset_id          = google_bigquery_dataset.evaluator.dataset_id
  table_id            = "evaluator_ratings"
  schema              = file("./files/evaluator-ratings-schema.json")
  deletion_protection = false
}

resource "google_service_account" "evaluator" {
  account_id   = "search-v2-evaluator"
  display_name = "search-v2-evaluator (Rails app)"
  description  = "Service account to provide access to BigQuery for the search-v2-evaluator Rails app"
}

resource "google_service_account_key" "evaluator" {
  service_account_id = google_service_account.evaluator.id
}

resource "google_project_iam_custom_role" "evaluator" {
  role_id     = "evaluator"
  title       = "search-v2-evaluator"
  description = "Enables write access to BigQuery for the search-v2-evaluator Rails app"

  permissions = [
    "bigquery.tables.get",
    "bigquery.tables.updateData",
  ]
}

resource "google_bigquery_table_iam_binding" "evaluator" {
  dataset_id = google_bigquery_dataset.evaluator.dataset_id
  table_id   = google_bigquery_table.evaluator_ratings.table_id
  role       = google_project_iam_custom_role.evaluator.role_id

  members = [
    "serviceAccount:${google_service_account.evaluator.email}",
  ]
}
