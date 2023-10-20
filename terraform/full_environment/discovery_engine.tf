# Creates and configures an unstructured datastore for Google Discovery Engine ("Vertex AI Search")
# see https://cloud.google.com/generative-ai-app-builder/docs/reference/rest/

module "govuk_content_discovery_engine" {
  source = "../modules/google_discovery_engine_restapi"

  engine_id = "govuk_content"
}
