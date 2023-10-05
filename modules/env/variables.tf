variable "domain" {
  type        = string
  description = "Domain suffix to be used to construct IAM groups"
}

variable "billing_id" {
  type        = string
  description = "Billing Account ex. 012345-678910-ABCDEF"
}

# variable "folder_id" {
#   type        = string
#   description = "Get Folder ID of above folder"
# }

variable "project_id" {
  type        = string
  description = "Project ID of project created within GCP"
}


# variable "env_code" {
#   type        = string
#   description = "Environment code, e.g. d, t, p"
# }

# variable "suffix" {
#   type        = string
#   description = "unique suffix"
# }

# variable "project_prefix" {
#   type        = string
#   description = "Project Prefix for all projects, e.g. prj-xxxxx"
#   default     = "prj"
# }

variable "services" {
  type        = list(string)
  description = "List of services (apis) to enable"
}

variable "location" {
  type        = string
  description = "Location ex US or EU"
  default     = "EU"
}

variable "kc_group" {
  type        = string
  description = "K+C gcp group to use"
}