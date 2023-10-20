output "google_cloud_discovery_engine_datastore_path" {
  description = "The full path of the datastore created by the module (for data ingestion)"
  value       = module.govuk_content_discovery_engine.datastore_path
}

output "google_cloud_discovery_engine_engine_path" {
  description = "The full path of the engine created by the module (for querying)"
  value       = module.govuk_content_discovery_engine.engine_path
}
