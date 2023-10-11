# Used to extract access token from the provider so we can call the REST API
data "google_client_config" "default" {
}

provider "restapi" {
  uri                  = "https://discoveryengine.googleapis.com/${var.gcp_discovery_engine_api_version}"
  write_returns_object = false
  headers = {
    "Authorization"       = "Bearer ${data.google_client_config.default.access_token}"
    "X-Goog-User-Project" = var.gcp_project_id
  }
}

locals {
  discovery_engine_collection_path = "/projects/${var.gcp_project_id}/locations/${var.gcp_discovery_engine_location}/collections/${var.gcp_discovery_engine_collection}"
}

resource "restapi_object" "discovery_engine_datastore" {
  depends_on   = [google_project_service.google_services]
  path         = "${local.discovery_engine_collection_path}/dataStores"
  query_string = "dataStoreId=${var.gcp_discovery_engine_data_store_id}"
  object_id    = var.gcp_discovery_engine_data_store_id
  data = jsonencode({
    displayName      = var.gcp_discovery_engine_data_store_id
    industryVertical = "GENERIC"
    solutionTypes    = ["SOLUTION_TYPE_SEARCH"]
    searchTier       = "STANDARD"
    contentConfig    = "CONTENT_REQUIRED"
    searchAddOns     = ["LLM"]
  })
  create_method = "POST"
}
