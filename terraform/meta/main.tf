terraform {
  cloud {
    organization = "govuk"
    workspaces {
      name = "search-api-v2-meta"
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

resource "google_project" "environment_project" {
  for_each = var.environments

  name       = "Search API V2 ${each.value}"
  project_id = "search-api-v2-${each.key}"

  folder_id       = var.google_cloud_folder
  billing_account = var.google_cloud_billing_account

  labels = {
    "programme"         = "govuk"
    "team"              = "govuk-search-improvement"
    "govuk_environment" = each.key
  }
}

# Required to be able to manage resources using Terraform in the environment-specific module(s)
resource "google_project_service" "cloudresourcemanager_service" {
  for_each = google_project.environment_project

  project                    = each.value.project_id
  service                    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

# Required to set up service accounts and manage dynamic credentials
resource "google_project_service" "iam_service" {
  for_each = google_project.environment_project

  project                    = each.value.project_id
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
}

# Required to manage dynamic credentials
resource "google_project_service" "iamcredentials_service" {
  for_each = google_project.environment_project

  project                    = each.value.project_id
  service                    = "iamcredentials.googleapis.com"
  disable_dependent_services = true
}

# Required to manage dynamic credentials
resource "google_project_service" "sts_service" {
  for_each = google_project.environment_project

  project                    = each.value.project_id
  service                    = "sts.googleapis.com"
  disable_dependent_services = true
}

# TODO: This project was manually created and its properties/dependent resources need to be fully
# reflected here eventually.
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

resource "tfe_workspace" "environment_workspace" {
  for_each = var.environments

  name        = "search-api-v2-${each.key}"
  project_id  = tfe_project.project.id
  description = "Provisions search-api-v2 resources for the ${each.value} environment"
  tag_names   = ["govuk", "search-api-v2", each.key]

  execution_mode = "remote"
}

resource "tfe_variable" "gcp_project_id" {
  for_each = var.environments

  workspace_id = tfe_workspace.environment_workspace[each.key].id
  category     = "terraform"
  description  = "The GCP project ID for the ${each.key} environment"

  key       = "gcp_project_id"
  value     = google_project.environment_project[each.key].id
  sensitive = false
}
