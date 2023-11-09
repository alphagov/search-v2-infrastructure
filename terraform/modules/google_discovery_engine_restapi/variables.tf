variable "datastore_id" {
  description = "The name of the datastore to create"
  type        = string
}

variable "engine_id" {
  description = "The name of the engine to create"
  type        = string
}

variable "search_tier" {
  type        = string
  description = "The tier of the Discovery Engine to use, e.g. STANDARD or ENTERPRISE"
  default     = "SEARCH_TIER_STANDARD"
}
