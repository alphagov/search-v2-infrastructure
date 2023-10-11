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

# Used to extract access token so we can call the REST API
data "google_client_config" "default" {
}

provider "restapi" {
  uri                  = "https://discoveryengine.googleapis.com/v1alpha"
  write_returns_object = false
  headers = {
    "Authorization" = "Bearer ${data.google_client_config.default.access_token}"
  }
}

locals {
  google_services = [
    # Required to create resources using Terraform
    "cloudresourcemanager.googleapis.com",
    "discoveryengine.googleapis.com"
  ]
  vertex_collection_path = "projects/${var.gcp_project_id}/locations/${var.gcp_vertex_location}/collections/${var.gcp_vertex_collection}"
}

resource "google_project_service" "google_services" {
  for_each                   = toset(local.google_services)
  project                    = var.gcp_project_id
  service                    = each.value
  disable_dependent_services = true
}

resource "restapi_object" "vertex_datastore" {
  path         = "${local.vertex_collection_path}/dataStores"
  query_string = "dataStoreId=${var.gcp_vertex_data_store_id}"
  object_id    = var.gcp_vertex_data_store_id
  data         = "{}"
}
