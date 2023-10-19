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
  organization = var.tfc_organization_name
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

# Set up Workload Identity Federation between Terraform Cloud and GCP
# see https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples
resource "google_iam_workload_identity_pool" "tfc_pool" {
  for_each = var.environments

  project                   = google_project.environment_project[each.key].project_id
  workload_identity_pool_id = "terraform-cloud-pool"

  display_name = "Terraform Cloud ID Pool"
  description  = "Pool to enable access to project resources for Terraform Cloud"
}

resource "google_iam_workload_identity_pool_provider" "tfc_provider" {
  for_each = var.environments

  project                            = google_project.environment_project[each.key].project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.tfc_pool[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = "terraform-cloud-provider"

  display_name = "Terraform Cloud ID Provider"
  description  = "Configures Terraform Cloud as an external identity provider for this project"

  attribute_mapping = {
    "google.subject"                        = "assertion.sub",
    "attribute.aud"                         = "assertion.aud",
    "attribute.terraform_run_phase"         = "assertion.terraform_run_phase",
    "attribute.terraform_project_id"        = "assertion.terraform_project_id",
    "attribute.terraform_project_name"      = "assertion.terraform_project_name",
    "attribute.terraform_workspace_id"      = "assertion.terraform_workspace_id",
    "attribute.terraform_workspace_name"    = "assertion.terraform_workspace_name",
    "attribute.terraform_organization_id"   = "assertion.terraform_organization_id",
    "attribute.terraform_organization_name" = "assertion.terraform_organization_name",
    "attribute.terraform_run_id"            = "assertion.terraform_run_id",
    "attribute.terraform_full_workspace"    = "assertion.terraform_full_workspace",
  }

  oidc {
    issuer_uri = "https://${var.tfc_hostname}"
  }

  attribute_condition = "assertion.sub.startsWith(\"organization:${var.tfc_organization_name}:project:${tfe_project.project.name}:workspace:${tfe_workspace.environment_workspace[each.key].name}\")"
}
