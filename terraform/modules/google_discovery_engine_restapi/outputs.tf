output "datastore_path" {
  description = "The full path of the datastore created by the module (for data ingestion)"
  value       = restapi_object.discovery_engine_datastore.api_data["name"]
}

output "datastore_default_branch_path" {
  description = "The full path of the default branch of the datastore created by the module (for data ingestion)"
  value       = "${restapi_object.discovery_engine_datastore.api_data["name"]}/branches/default_branch"
}

output "serving_config_path" {
  description = "The serving config for the engine created by the module (for querying)"
  # TODO: Revert to this once Vertex engine bug is fixed
  # value       = "${restapi_object.discovery_engine_engine.api_data["name"]}/servingConfigs/default_search"
  value = "${restapi_object.discovery_engine_datastore.api_data["name"]}/servingConfigs/default_search"
}
