output "datastore_path" {
  description = "The full path of the datastore created by the module (for data ingestion)"
  value       = restapi_object.discovery_engine_datastore.api_data["name"]
}

output "serving_config_path" {
  description = "The serving config for the engine created by the module (for querying)"
  value       = "${restapi_object.discovery_engine_engine.api_data["name"]}/servingConfigs/default_serving_config"
}
