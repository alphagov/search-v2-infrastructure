terraform {
  cloud {
    organization = "govuk"
    workspaces {
      name = "search-v2-infrastructure-integration"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.1.0"
    }
  }

  required_version = "~> 1.6"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

locals {
  google_services = [
    "cloudresourcemanager.googleapis.com",
    "discoveryengine.googleapis.com"
  ]
}

resource "google_project_service" "google_services" {
  for_each                   = toset(local.google_services)
  project                    = var.gcp_project_id
  service                    = each.value
  disable_dependent_services = true
}

module "gcloud" {
  source        = "terraform-google-modules/gcloud/google"
  version       = "~> 3.3.0"
  skip_download = false

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "version"
  destroy_cmd_entrypoint = "gcloud"
  destroy_cmd_body       = "version"
}
