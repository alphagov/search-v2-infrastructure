terraform {
  required_version = ">= 0.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "< 5.0"
    }
  }
}

# import {
#   to = google_project.base
#   id = "gds-search"
# }



# resource "random_string" "suffix" {
#   length  = 6
#   special = false
#   lower   = true
#   upper   = false
# }

module "dev" {
  source         = "../../modules/env"
  # suffix         = random_string.suffix.result
  domain         = var.domain
  billing_id     = var.billing_id
  # folder_id      = var.folder_id
  # env_code       = var.env_code
  # project_prefix = var.project_prefix
  services       = var.services
  location       = var.location
  project_id = var.project_id
  kc_group = var.kc_group
}