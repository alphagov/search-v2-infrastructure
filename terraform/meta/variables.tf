variable "environments" {
  type        = map(string)
  description = "Names of environments to create resource sets for"
  default = {
    dev         = "Development"
    integration = "Integration"
    staging     = "Staging"
    production  = "Production"
  }
}

variable "google_cloud_folder" {
  type        = string
  description = "The ID of the Google Cloud folder to create projects under"
}

variable "google_cloud_billing_account" {
  type        = string
  description = "The ID of the Google Cloud billing account to associate projects with"
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
