terraform {
  cloud {
    organization = "govuk"
    workspaces {
      project = "govuk-search-api-v2"
      name    = "search-api-v2-meta"
    }
  }

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.49.2"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.2"
    }
  }

  required_version = "~> 1.6"
}

provider "tfe" {
  organization = "govuk"
}

provider "google" {
}

# Overarching Terraform Cloud project for all workspaces
resource "tfe_project" "project" {
  name = "govuk-search-api-v2"
}

# NOTE: This is used to store the state for this module itself (see `terraform` block above). It was
# initially created using a local backend, and then migrated to a remote backend.
resource "tfe_workspace" "meta_workspace" {
  name        = "search-api-v2-meta"
  project_id  = tfe_project.project.id
  description = "Meta workspace for cross-environment TF Cloud resources (state backend only)"
  tag_names   = ["govuk", "search-api-v2"]

  execution_mode = "local"
}

module "environment_integration" {
  source = "./modules/environment"

  name                         = "integration"
  google_cloud_billing_account = var.google_cloud_billing_account
  google_cloud_folder          = var.google_cloud_folder
  tfc_project                  = tfe_project.project
}

module "environment_staging" {
  source = "./modules/environment"

  name                         = "staging"
  google_cloud_billing_account = var.google_cloud_billing_account
  google_cloud_folder          = var.google_cloud_folder
  tfc_project                  = tfe_project.project
}

module "environment_production" {
  source = "./modules/environment"

  name                         = "production"
  google_cloud_billing_account = var.google_cloud_billing_account
  google_cloud_folder          = var.google_cloud_folder
  tfc_project                  = tfe_project.project


  # NOTE: There are limits on the Google side on how high we are permitted to set these quotas. If
  # you attempt to increase these beyond the ceiling, a `COMMON_QUOTA_CONSUMER_OVERRIDE_TOO_HIGH`
  # error will be raised (including some metadata that should tell you what the current ceiling is)
  # and you will need to manually request a quota increase from Google through the console first
  # (see the environment module for the exact quota names you need to request increases for).
  discovery_engine_quota_search_requests_per_minute = 2000
  discovery_engine_quota_documents                  = 2000000
}
