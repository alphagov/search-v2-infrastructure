# Creates and configures service accounts, IAM roles, role bindings, and keys for `search-api-v2` to
# be able to access the Discovery Engine API.

resource "google_service_account" "api_read" {
  account_id   = "search-api-v2-read"
  display_name = "search-api-v2 (Rails API app; read only)"
  description  = "Read-only service account to provide access to the search-api-v2 Rails app"
}

resource "google_service_account" "api_write" {
  account_id   = "search-api-v2-write"
  display_name = "search-api-v2 (Document Sync Worker; write only)"
  description  = "Write-only service account to provide access to the search-api-v2 Document Sync Worker"
}

resource "google_project_iam_custom_role" "api_read" {
  role_id     = "search_api_v2_read"
  title       = "search-api-v2 (read only)"
  description = "Enables read-only access to the search-api-v2 Rails app"

  permissions = [
    "discoveryengine.servingConfigs.search",
  ]
}

resource "google_project_iam_custom_role" "api_write" {
  role_id     = "search_api_v2_write"
  title       = "search-api-v2 (write only)"
  description = "Enabled write-only access to the search-api-v2 Document Sync Worker"

  permissions = [
    "discoveryengine.dataStores.get",
    "discoveryengine.documents.*",
    "discoveryengine.operations.get",
  ]
}

resource "google_project_iam_binding" "api_read" {
  project = var.gcp_project_id
  role    = "search_api_v2_read"

  members = [
    "serviceAccount:${google_service_account.api_read.email}"
  ]
}

resource "google_project_iam_binding" "api_write" {
  project = var.gcp_project_id
  role    = "search_api_v2_write"

  members = [
    "serviceAccount:${google_service_account.api_write.email}"
  ]
}

resource "google_service_account_key" "api_read" {
  service_account_id = google_service_account.api_read.id
}

resource "google_service_account_key" "api_write" {
  service_account_id = google_service_account.api_write.id
}
