# Creates and configures an unstructured datastore for Google Discovery Engine ("Vertex AI Search")
# see https://cloud.google.com/generative-ai-app-builder/docs/reference/rest/

# Used to extract access token from the provider so we can call the REST API
data "google_client_config" "default" {}

# Using REST API provider as a "temporary" workaround, as there are no native Terraform resources
# for Discovery Engine in the Google provider yet
provider "restapi" {
  uri = "https://discoveryengine.googleapis.com/${var.discovery_engine_api_version}/projects/${var.gcp_project_id}/locations/${var.discovery_engine_location}/collections/${var.discovery_engine_collection}"

  # Writes return an "operation" reference rather than the object being written
  write_returns_object = false

  # Discovery Engine API uses POST for create, PATCH for update
  create_method = "POST"
  update_method = "PATCH"

  headers = {
    # Piggyback on the the Terraform provider's generated temporary credentials to authenticate
    # to the API with
    "Authorization"       = "Bearer ${data.google_client_config.default.access_token}"
    "X-Goog-User-Project" = var.gcp_project_id
  }
}

# Enable the Discovery Engine API
resource "google_project_service" "discoveryengine" {
  project                    = var.gcp_project_id
  service                    = "discoveryengine.googleapis.com"
  disable_dependent_services = true
}

# A datastore for content to be ingested into
# API resource: v1alpha.projects.locations.collections.dataStores
resource "restapi_object" "discovery_engine_datastore" {
  depends_on = [google_project_service.discoveryengine]
  path       = "/dataStores"
  object_id  = var.discovery_engine_datastore_id
  data = jsonencode({
    dataStoreId      = var.discovery_engine_datastore_id
    displayName      = var.discovery_engine_datastore_id
    industryVertical = "GENERIC"
    solutionTypes    = ["SOLUTION_TYPE_SEARCH"]
    searchTier       = var.discovery_engine_tier
    contentConfig    = "CONTENT_REQUIRED" # makes the engine type "unstructured"
    searchAddOns     = ["LLM"]            # this is the only valid value supported by the API
  })
}

# The data schema for the datastore (while datastores only support a single schema, the API resource
# relationship is one-to-many)
# API resource: v1alpha.projects.locations.collections.dataStores.schemas
resource "restapi_object" "discovery_engine_datastore_schema" {
  depends_on   = [restapi_object.discovery_engine_datastore]
  path         = "/dataStores/${var.discovery_engine_datastore_id}/schemas"
  query_string = "schemaId=${var.discovery_engine_datastore_schema_name}"
  object_id    = var.discovery_engine_datastore_schema_name
  data = jsonencode({
    name         = var.discovery_engine_datastore_schema_name
    structSchema = file("${path.module}/files/datastore_schema.json")
  })
}
