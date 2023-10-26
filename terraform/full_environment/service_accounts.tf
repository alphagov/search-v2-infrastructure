# Creates and configures service accounts, IAM roles, role bindings, and keys for `search-api-v2` to
# be able to access the Discovery Engine API.
resource "google_service_account" "api" {
  account_id   = "search-api-v2"
  display_name = "search-api-v2 (Rails API app and document sync worker)"
  description  = "Service account to provide access to the search-api-v2 Rails app and document sync worker"
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
    "discoveryengine.documents.create",
    "discoveryengine.documents.delete",
    "discoveryengine.documents.get",
    "discoveryengine.documents.import",
    "discoveryengine.documents.list",
    "discoveryengine.documents.update",
    "discoveryengine.operations.get",
  ]
}

resource "google_project_iam_binding" "api_read" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.api_read.id

  members = [
    google_service_account.api.member
  ]
}

resource "google_project_iam_binding" "api_write" {
  project = var.gcp_project_id
  role    = google_project_iam_custom_role.api_write.id

  members = [
    google_service_account.api.member
  ]
}

resource "google_service_account_key" "api" {
  service_account_id = google_service_account.api.id
}

resource "aws_secretsmanager_secret" "key" {
  name                    = "govuk/search-api-v2/google-cloud-credentials"
  recovery_window_in_days = 0 # Force delete to allow re-applying immediately after destroying
}

resource "aws_secretsmanager_secret_version" "key" {
  secret_id = aws_secretsmanager_secret.key.id
  secret_string = jsonencode({
    "credentials.json" = base64decode(google_service_account_key.api.private_key)
  })
}
