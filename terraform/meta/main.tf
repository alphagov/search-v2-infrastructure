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

module "environment_dev" {
  source = "./modules/environment"

  google_cloud_billing_account = var.google_cloud_billing_account
  google_cloud_folder          = var.google_cloud_folder
  tfc_project                  = tfe_project.project

  name                        = "dev"
  display_name                = "Development"
  has_deployed_service_in_aws = false
  terraform_module            = "dev_environment"
}


module "environment_integration" {
  source = "./modules/environment"

  google_cloud_billing_account = var.google_cloud_billing_account
  google_cloud_folder          = var.google_cloud_folder
  tfc_project                  = tfe_project.project

  name                        = "integration"
  display_name                = "Integration"
  has_deployed_service_in_aws = true
  terraform_module            = "full_environment"
}

module "environment_staging" {
  source = "./modules/environment"

  google_cloud_billing_account = var.google_cloud_billing_account
  google_cloud_folder          = var.google_cloud_folder
  tfc_project                  = tfe_project.project

  name                        = "staging"
  display_name                = "Staging"
  has_deployed_service_in_aws = true
  terraform_module            = "full_environment_without_events"
}

module "environment_production" {
  source = "./modules/environment"

  google_cloud_billing_account = var.google_cloud_billing_account
  google_cloud_folder          = var.google_cloud_folder
  tfc_project                  = tfe_project.project

  name                        = "production"
  display_name                = "Production"
  has_deployed_service_in_aws = true
  terraform_module            = "full_environment_without_events"
}
