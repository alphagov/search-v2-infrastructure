# Creates and configures an unstructured datastore for Google Discovery Engine ("Vertex AI Search")
# see https://cloud.google.com/generative-ai-app-builder/docs/reference/rest/

# Enable the Discovery Engine API
resource "google_project_service" "discoveryengine" {
  project                    = var.gcp_project_id
  service                    = "discoveryengine.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

module "govuk_content_discovery_engine" {
  source = "../modules/google_discovery_engine_restapi"

  depends_on = [google_project_service.discoveryengine]

  engine_id = "govuk_content"
}
