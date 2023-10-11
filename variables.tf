variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID of the project to create infrastructure in, e.g. search-api-v2-integration"
}

variable "gcp_region" {
  type        = string
  description = "GCP region to create non-global infrastructure in, e.g. europe-west2"
  default     = "europe-west2"
}

variable "gcp_vertex_location" {
  type        = string
  description = "GCP location to create Vertex Datastore instance in, e.g. global"
  default     = "global"
}

variable "gcp_vertex_collection" {
  type        = string
  description = "The collection to use for Vertex Search, currently only `default_collection` is supported"
  default     = "default_collection"
}

variable "gcp_vertex_data_store_id" {
  type        = string
  description = "The ID of the Vertex Datastore instance to create, e.g. search-api-v2-integration"
  default     = "govuk-structured"
}
