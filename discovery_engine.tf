# Creates and configures an unstructured datastore for Google Discovery Engine ("Vertex AI Search")
# see https://cloud.google.com/generative-ai-app-builder/docs/reference/rest/

# Used to extract access token from the provider so we can call the REST API
data "google_client_config" "default" {}

# Using REST API provider as a "temporary" workaround, as there are no native Terraform resources
# for Discovery Engine in the Google provider yet
provider "restapi" {
  uri = "https://discoveryengine.googleapis.com/${var.discovery_engine_api_version}/projects/${var.gcp_project_id}/locations/${var.discovery_engine_location}/collections/default_collection"

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

# The datastore to store content in
#
# Currently (October 2023), the datastore is the core entity of the Discovery Engine API, used for
# both querying and storing content. There are plans for this to change and for an "engine" resource
# to be introduced, at which point we will need to create an engine and associate it with the
# datastore.
#
# API resource: v1alpha.projects.locations.collections.dataStores
resource "restapi_object" "discovery_engine_datastore" {
  depends_on = [google_project_service.discoveryengine]

  path      = "/dataStores"
  object_id = var.discovery_engine_datastore_id

  # API uses query strings to specify ID of the resource to create (not payload)
  create_path = "/dataStores?dataStoreId=${var.discovery_engine_datastore_id}"

  data = jsonencode({
    displayName      = var.discovery_engine_datastore_id
    industryVertical = "GENERIC"
    solutionTypes    = ["SOLUTION_TYPE_SEARCH"]
    searchTier       = var.discovery_engine_tier
    contentConfig    = "CONTENT_REQUIRED" # makes the engine type "unstructured"
    searchAddOns     = ["LLM"]            # this is the only valid value supported by the API
  })
}

# The data schema for the datastore
#
# The API resource relationship is one-to-many, but currently only a single schema is supported and
# it's automatically created as `default_schema` (with an empty content) on creation of the
# datastore.
#
# API resource: v1alpha.projects.locations.collections.dataStores.schemas
resource "restapi_object" "discovery_engine_datastore_schema" {
  depends_on = [restapi_object.discovery_engine_datastore]

  path      = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/schemas"
  object_id = "default_schema"

  # Since the default schema is created automatically with the datastore, we need to update even on
  # initial Terraform resource creation
  create_method = "PATCH"
  create_path   = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/schemas/default_schema"

  data = jsonencode({
    jsonSchema = file("${path.module}/files/datastore_schema.json")
  })
}
