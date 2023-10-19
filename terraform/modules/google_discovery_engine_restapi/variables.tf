variable "engine_id" {
  description = "The name of the engine and datastore to create"
  type        = string
}

variable "tier" {
  type        = string
  description = "The tier of the Discovery Engine to use, e.g. STANDARD or ENTERPRISE"
  default     = "STANDARD"
}

variable "json_schema" {
  type        = string
  description = "A JSON schema to use for the datastore"
}
