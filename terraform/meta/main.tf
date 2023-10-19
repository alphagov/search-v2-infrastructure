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
  organization = var.tfc_organization_name
}

provider "google" {
}

locals {
  # Environments that exist on AWS, i.e. all environments except those that are local-only
  aws_environments = setsubtract(keys(var.environments), var.local_only_environments)
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

data "tfe_oauth_client" "github" {
  organization     = var.tfc_organization_name
  service_provider = "github"
}

resource "tfe_workspace" "discovery_engine_workspace" {
  for_each = var.environments

  name        = "search-api-v2-discovery-engine-${each.key}"
  project_id  = tfe_project.project.id
  description = "Provisions search-api-v2 Discovery Engine resources for the ${each.value} environment"
  tag_names   = ["govuk", "search-api-v2", "search-api-v2-discovery-engine", each.key]

  source_name = "search-v2-infrastructure meta module"
  source_url  = "https://github.com/alphagov/search-v2-infrastructure/tree/main/terraform/meta"

  execution_mode    = "remote"
  working_directory = "terraform/discovery_engine"
  auto_apply        = false # TODO: Change me once setup looks stable

  vcs_repo {
    identifier     = "alphagov/search-v2-infrastructure"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
  }
}

data "tfe_variable_set" "aws_credentials" {
  for_each = local.aws_environments

  name = "aws-credentials-${each.key}"
}

resource "tfe_workspace_variable_set" "aws_workspace_credentials" {
  for_each = local.aws_environments

  variable_set_id = data.tfe_variable_set.aws_credentials[each.key].id
  workspace_id    = tfe_workspace.discovery_engine_workspace[each.key].id
}

resource "tfe_variable" "gcp_project_id" {
  for_each = var.environments

  workspace_id = tfe_workspace.discovery_engine_workspace[each.key].id
  category     = "terraform"
  description  = "The GCP project ID for the ${each.key} environment"

  key       = "gcp_project_id"
  value     = google_project.environment_project[each.key].project_id
  sensitive = false
}

# Set up Workload Identity Federation between Terraform Cloud and GCP
# see https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples
resource "google_iam_workload_identity_pool" "tfc_pool" {
  for_each = var.environments

  project                   = google_project.environment_project[each.key].project_id
  workload_identity_pool_id = "terraform-cloud-id-pool"

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

  attribute_condition = "assertion.sub.startsWith(\"organization:${var.tfc_organization_name}:project:${tfe_project.project.name}:workspace:${tfe_workspace.discovery_engine_workspace[each.key].name}\")"
}

resource "google_service_account" "tfc_service_account" {
  for_each = var.environments

  project = google_project.environment_project[each.key].project_id

  account_id   = "tfc-service-account"
  display_name = "Terraform Cloud Service Account"
  description  = "Used by Terraform Cloud to manage resources in this project through Workload Identity Federation"
}

resource "google_service_account_iam_member" "tfc_service_account_member" {
  for_each = var.environments

  service_account_id = google_service_account.tfc_service_account[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool[each.key].name}/*"
}

resource "google_project_iam_member" "tfc_project_member" {
  for_each = var.environments

  project = google_project.environment_project[each.key].project_id

  role   = "roles/owner"
  member = "serviceAccount:${google_service_account.tfc_service_account[each.key].email}"
}

resource "tfe_variable" "enable_gcp_provider_auth" {
  for_each = var.environments

  workspace_id = tfe_workspace.discovery_engine_workspace[each.key].id

  key      = "TFC_GCP_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable Workload Identity Federation on GCP"
}

resource "tfe_variable" "tfc_gcp_workload_provider_name" {
  for_each = var.environments

  workspace_id = tfe_workspace.discovery_engine_workspace[each.key].id

  key      = "TFC_GCP_WORKLOAD_PROVIDER_NAME"
  value    = google_iam_workload_identity_pool_provider.tfc_provider[each.key].name
  category = "env"

  description = "The workload provider name to authenticate against on GCP"
}

resource "tfe_variable" "tfc_gcp_service_account_email" {
  for_each = var.environments

  workspace_id = tfe_workspace.discovery_engine_workspace[each.key].id

  key      = "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL"
  value    = google_service_account.tfc_service_account[each.key].email
  category = "env"

  description = "The GCP service account email runs will use to authenticate"
}
