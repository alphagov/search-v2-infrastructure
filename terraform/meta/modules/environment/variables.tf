variable "name" {
  type        = string
  description = "A short name for this environment (used in resource IDs)"
}

variable "display_name" {
  type        = string
  description = "A longer, more descriptive name for this environment"
}

variable "has_deployed_service_in_aws" {
  type        = bool
  description = "Whether this environment has a deployed API service (if so, service accounts and access keys are provisioned for consumption by Kubernetes)"
  default     = true
}

variable "terraform_module" {
  type        = string
  description = "The name of the Terraform module for this environment (used as working directory)"
}

variable "google_cloud_folder" {
  type        = string
  description = "The ID of the Google Cloud folder to create projects under"
}

variable "google_cloud_billing_account" {
  type        = string
  description = "The ID of the Google Cloud billing account to associate projects with"
}

variable "tfc_project" {
  type = object({
    id   = string
    name = string
  })
  description = "The Terraform Cloud/Enterprise project to create workspaces under"
}

variable "tfc_hostname" {
  type        = string
  description = "The hostname of the Terraform Cloud/Enterprise instance to use"
  default     = "app.terraform.io"
}

variable "tfc_organization_name" {
  type        = string
  description = "The name of the Terraform Cloud/Enterprise organization to use"
  default     = "govuk"
}
