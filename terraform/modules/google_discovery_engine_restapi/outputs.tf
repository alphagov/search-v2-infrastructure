output "datastore_path" {
  description = "The full path of the datastore created by the module (for data ingestion)"
  value       = restapi_object.discovery_engine_datastore.api_data["name"]
}

output "engine_path" {
  description = "The full path of the engine created by the module (for querying)"
  # TODO: This is currently the same as datastore_path as the API doesn't support creating engines
  # yet. However, once it does, this can be updated accordingly and the API will be able to use the
  # engine instead (as the API for querying will continue to be a `servingConfig` nested underneath
  # this endpoint, only the endpoint itself changes)
  value = restapi_object.discovery_engine_datastore.api_data["name"]
}
