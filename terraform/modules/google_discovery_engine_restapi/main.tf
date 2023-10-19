terraform {
  required_providers {
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 1.18"
    }
  }

  required_version = "~> 1.6"
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
  path      = "/dataStores"
  object_id = var.engine_id

  # API uses query strings to specify ID of the resource to create (not payload)
  create_path = "/dataStores?dataStoreId=${var.engine_id}"

  data = jsonencode({
    displayName      = var.engine_id
    industryVertical = "GENERIC"
    solutionTypes    = ["SOLUTION_TYPE_SEARCH"]
    searchTier       = var.tier
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
  for_each = restapi_object.discovery_engine_datastore

  path      = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/schemas"
  object_id = "default_schema"

  # Since the default schema is created automatically with the datastore, we need to update even on
  # initial Terraform resource creation
  create_method = "PATCH"
  create_path   = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/schemas/default_schema"

  data = jsonencode({
    jsonSchema = var.json_schema
  })
}
