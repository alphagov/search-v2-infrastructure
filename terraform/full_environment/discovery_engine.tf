# Creates and configures an unstructured datastore for Google Discovery Engine ("Vertex AI Search")
# see https://cloud.google.com/generative-ai-app-builder/docs/reference/rest/

module "govuk_content_discovery_engine" {
  source = "../modules/google_discovery_engine_restapi"

  engine_id = "govuk_content"
}

resource "aws_secretsmanager_secret" "discovery_engine_configuration" {
  name                    = "govuk/search-api-v2/google-cloud-credentials"
  recovery_window_in_days = 0 # Force delete to allow re-applying immediately after destroying
}

resource "aws_secretsmanager_secret_version" "discovery_engine_configuration" {
  secret_id = aws_secretsmanager_secret.key.id
  secret_string = jsonencode({
    "DISCOVERY_ENGINE_DATASTORE" = module.govuk_content_discovery_engine.datastore_path,
    "DISCOVERY_ENGINE_ENGINE"    = module.govuk_content_discovery_engine.engine_path,
  })
}
