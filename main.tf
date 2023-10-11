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
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 1.18.2"
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
    # Required to create resources using Terraform
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
