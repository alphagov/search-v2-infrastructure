terraform {
  required_providers {
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 1.19.1"
    }
  }

  required_version = "~> 1.7"
}

locals {
  servingConfigs  = yamldecode(file("${path.module}/files/servingConfigs/servingConfigs.yml"))
  boostControls   = yamldecode(file("${path.module}/files/controls/boosts.yml"))
  synonymControls = yamldecode(file("${path.module}/files/controls/synonyms.yml"))
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
      searchAddOns = [] # "SEARCH_ADD_ON_LLM" is the only valid value supported by the API - leave empty to disable
    }
  })
}

resource "restapi_object" "discovery_engine_serving_config" {
  depends_on = [
    restapi_object.discovery_engine_boost_control,
    restapi_object.discovery_engine_synonym_control
  ]
  path      = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/servingConfigs/default_search?updateMask=boost_control_ids,synonyms_control_ids"
  object_id = "default_search"

  # Since the default serving config is created automatically with the datastore, we need to update
  # even on initial Terraform resource creation
  create_method = "PATCH"
  create_path   = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/servingConfigs/default_search?updateMask=boost_control_ids,synonyms_control_ids"
  update_method = "PATCH"
  update_path   = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/servingConfigs/default_search?updateMask=boost_control_ids,synonyms_control_ids"
  read_path     = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/servingConfigs/default_search"

  data = jsonencode({
    boostControlIds    = keys(local.boostControls)
    synonymsControlIds = keys(local.synonymControls)
  })
}

# Handles additional serving configs beyond the default_search serving config
resource "restapi_object" "discovery_engine_serving_config_additional" {
  depends_on = [
    restapi_object.discovery_engine_boost_control,
    restapi_object.discovery_engine_synonym_control
  ]

  for_each = local.servingConfigs

  path      = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/servingConfigs"
  object_id = each.key

  create_method = "CREATE"
  create_path   = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/servingConfigs?servingConfigId=${each.key}"
  update_method = "PATCH"
  update_path   = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/servingConfigs/${each.key}"
  read_path     = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/servingConfigs/${each.key}"

  data = jsonencode({
    name = each.key,
    displayName = each.key,
    solutionType = "SOLUTION_TYPE_SEARCH"
    boostControlIds = lookup(each.value, "boostControlIds", [])
    synonymsControlIds = lookup(each.value, "synonymsControlIds", [])
  })
}

resource "restapi_object" "discovery_engine_boost_control" {
  for_each = local.boostControls

  path      = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/controls"
  object_id = each.key

  # API uses query strings to specify ID of the resource to create (not payload)
  create_path = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/controls?controlId=${each.key}"

  data = jsonencode({
    name        = each.key
    displayName = each.key

    solutionType = "SOLUTION_TYPE_SEARCH"
    useCases     = ["SEARCH_USE_CASE_SEARCH"]

    boostAction = each.value
  })
}

resource "restapi_object" "discovery_engine_synonym_control" {
  for_each = local.synonymControls

  path      = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/controls"
  object_id = each.key

  # API uses query strings to specify ID of the resource to create (not payload)
  create_path = "/dataStores/${restapi_object.discovery_engine_datastore.object_id}/controls?controlId=${each.key}"

  data = jsonencode({
    name        = each.key
    displayName = each.key

    solutionType = "SOLUTION_TYPE_SEARCH"
    useCases     = ["SEARCH_USE_CASE_SEARCH"]

    synonymsAction = {
      synonyms = each.value
    }
  })
}
