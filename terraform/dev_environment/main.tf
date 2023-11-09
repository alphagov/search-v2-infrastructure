terraform {
  cloud {
    organization = "govuk"
    workspaces {
      project = "govuk-search-api-v2"

      # All workspaces for this module have this tag set up by `meta` module
      tags = ["search-api-v2-dev_environment"]
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

# Used to extract access token from the provider so we can call the REST API
data "google_client_config" "default" {}

# Using REST API provider as a "temporary" workaround, as there are no native Terraform resources
# for Discovery Engine in the Google provider yet
provider "restapi" {
  uri = "https://discoveryengine.googleapis.com/${var.discovery_engine_api_version}/projects/${var.gcp_project_id}/locations/${var.discovery_engine_location}/collections/default_collection"

  # Writes in GCP APIs return an "operation" reference rather than the object being written
  write_returns_object = false

  # Discovery Engine API uses POST for create, PATCH for update
  create_method = "POST"
  update_method = "PATCH"

  headers = {
    # Piggyback on the the Terraform provider's generated temporary credentials to authenticate
    # to the API with
    "Authorization"       = "Bearer ${data.google_client_config.default.access_token}"
    "X-Goog-User-Project" = var.gcp_project_id
  }
}

module "engine" {
  source   = "../modules/google_discovery_engine_restapi"
  for_each = var.engines

  datastore_id = each.key
  engine_id    = each.key
}
