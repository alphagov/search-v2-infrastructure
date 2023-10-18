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
  }

  required_version = "~> 1.6"
}

provider "tfe" {
  organization = "govuk"
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
  description = "Provisions search-api-v2 resources for the ${each.key} environment"
  tag_names   = ["govuk", "search-api-v2", each.key]

  execution_mode = "remote"
}

resource "tfe_variable" "gcp_project_id" {
  for_each = var.environments

  workspace_id = tfe_workspace.environment_workspace[each.key].id
  category     = "terraform"
  description  = "The GCP project ID for the ${each.key} environment"

  key       = "gcp_project_id"
  value     = "search-api-v2-${each.key}"
  sensitive = false
}
