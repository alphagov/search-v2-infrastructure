terraform {
  cloud {
    organization = "govuk"
    workspaces {
      name = "search-api-v2-terraformcloud"
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

resource "tfe_project" "project" {
  name = "govuk-search-api-v2"
}

# Note: This meta-workspace is used to store the state for this set of Terraform resources. These
# resources were initially created locally and the state then imported into Terraform Cloud.
resource "tfe_workspace" "terraformcloud_workspace" {
  name        = "search-api-v2-terraformcloud"
  project_id  = tfe_project.project.id
  description = "State storage workspace for cross-environment TF Cloud resources"
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
