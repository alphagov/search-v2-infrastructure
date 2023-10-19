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
