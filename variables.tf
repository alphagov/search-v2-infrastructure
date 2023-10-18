variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID of the project to create infrastructure in, e.g. search-api-v2-integration"
}

variable "gcp_region" {
  type        = string
  description = "GCP region to create non-global infrastructure in, e.g. europe-west2"
  default     = "europe-west2"
}

variable "discovery_engine_api_version" {
  type        = string
  description = "The version of the Discovery Engine API to use, e.g. v1alpha"
  # Defaulting to `v1alpha` as `v1beta` and `v1` APIs don't support datastore creation yet (as of
  # October 2023)
  default = "v1alpha"
}

variable "discovery_engine_location" {
  type        = string
  description = "GCP location to create Discovery Engine Datastore instance in, e.g. global"
  # As of October 2023, we must use `global` as some event-related features are only available
  # there, but this may change before going live
  default = "global"
}

variable "discovery_engine_tier" {
  type        = string
  description = "The tier of the Discovery Engine to use, e.g. STANDARD or ENTERPRISE"
  default     = "STANDARD"
}

variable "discovery_engine_datastore_ids" {
  type        = set(string)
  description = "A list of IDs for Discovery Engine Datastore instances to create"
  default     = ["govuk-content"]
}
