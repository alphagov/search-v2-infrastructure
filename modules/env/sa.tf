# User Event Pipeline
resource "google_service_account" "user_event_pipeline" {
  account_id   = "discovery-user-event-pipeline"
  display_name = "discovery-user-event-pipeline"
  project      = data.google_project.base.project_id
}

# Search
resource "google_service_account" "search" {
  account_id   = "discoveryengine-search"
  display_name = "discoveryengine-search"
  project      = data.google_project.base.project_id
}

# Index Manager
resource "google_service_account" "index_manager" {
  account_id   = "discoveryengine-index-manager"
  display_name = "discoveryengine-index-manager"
  project      = data.google_project.base.project_id
}