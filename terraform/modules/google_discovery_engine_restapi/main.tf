terraform {
  required_providers {
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 1.18"
    }
  }

  required_version = "~> 1.6"
}

locals {
  boostControls = yamldecode(file("${path.module}/files/controls/boosts.yml"))
}

# The datastore to store content in
#
# API resource: v1alpha.projects.locations.collections.dataStores
resource "restapi_object" "discovery_engine_datastore" {
  path      = "/dataStores"
  object_id = var.datastore_id

  # API uses query strings to specify ID of the resource to create (not payload)
  create_path = "/dataStores?dataStoreId=${var.datastore_id}"

  data = jsonencode({
    displayName      = var.datastore_id
    industryVertical = "GENERIC"
    solutionTypes    = ["SOLUTION_TYPE_SEARCH"]
    contentConfig    = "CONTENT_REQUIRED" # makes the engine type "unstructured"
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

# The engine used for querying the datastore
#
# API resource: v1alpha.projects.locations.collections.engines
resource "restapi_object" "discovery_engine_engine" {
  path      = "/engines"
  object_id = var.engine_id

  # API uses query strings to specify ID of the resource to create (not payload)
  create_path = "/engines?engineId=${var.engine_id}"

  data = jsonencode({
    displayName = var.engine_id,
    dataStoreIds = [
      var.datastore_id
    ],
    solutionType = "SOLUTION_TYPE_SEARCH",
    commonConfig = {
      companyName = "GOV.UK"
    },
    searchEngineConfig = {
      searchTier   = var.search_tier,
      searchAddOns = ["SEARCH_ADD_ON_LLM"] # this is the only valid value supported by the API
    }
  })
}

resource "restapi_object" "discovery_engine_serving_config" {
  path      = "/engines/${restapi_object.discovery_engine_engine.object_id}/servingConfigs"
  object_id = "default_serving_config"

  # Since the default serving config is created automatically with the datastore, we need to update
  # even on initial Terraform resource creation
  create_method = "PATCH"
  create_path   = "/engines/${restapi_object.discovery_engine_engine.object_id}/servingConfigs/default_serving_config"
  update_method = "PATCH"

  # Stop Terraform from messing with any other fields in the serving config
  query_string = "updateMask=boostControlIds"

  data = jsonencode({
    boostControlIds = keys(local.boostControls)
  })
}

resource "restapi_object" "discovery_engine_boost_control" {
  for_each = local.boostControls

  path      = "/engines/${restapi_object.discovery_engine_engine.object_id}/controls"
  object_id = each.key

  # API uses query strings to specify ID of the resource to create (not payload)
  create_path = "/engines/${restapi_object.discovery_engine_engine.object_id}/controls?controlId=${each.key}"

  data = jsonencode({
    name        = each.key
    displayName = each.key

    solutionType = "SOLUTION_TYPE_SEARCH"
    useCases     = ["SEARCH_USE_CASE_SEARCH"]

    boostAction = each.value
  })
}
