variable "domain" {
  type        = string
  description = "Domain suffix to be used to construct IAM groups"
}

variable "folder_id" {
  type        = string
  description = "Get Folder ID of above folder"
}

variable "id1" {
  type        = string
  description = "Principal for IAM role #1"
}

variable "id2" {
  type        = string
  description = "Principal for IAM role #2"
}

variable "type" {
  type        = string
  description = "Principal Type: user or group"
}

variable "create_discoveryengine_groups" {
  type        = bool
  default     = true
  description = "Discovery Engine groups may only be created once per domain"
}