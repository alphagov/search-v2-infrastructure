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

resource "google_project_service" "discovery_engine_service" {
  project                    = var.gcp_project_id
  service                    = "discoveryengine.googleapis.com"
  disable_dependent_services = true
}
