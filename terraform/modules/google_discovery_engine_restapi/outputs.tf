output "datastore_path" {
  description = "The full path of the datastore created by the module (for data ingestion)"
  value       = restapi_object.discovery_engine_datastore.api_data["name"]
}

output "serving_config_path" {
  description = "The serving config for the engine created by the module (for querying)"
  # TODO: This is currently defined through the datastore path as the API doesn't support creating
  # engines yet. However, once it does, this can be updated accordingly and the API will be able to
  # use a servingConfig on the engine instead.
  value = "${restapi_object.discovery_engine_datastore.api_data["name"]}/servingConfigs/default_serving_config"
}
