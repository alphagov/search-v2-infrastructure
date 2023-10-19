terraform {
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

resource "google_project" "environment_project" {
  name       = "Search API V2 ${var.display_name}"
  project_id = "search-api-v2-${var.name}"

  folder_id       = var.google_cloud_folder
  billing_account = var.google_cloud_billing_account

  labels = {
    "programme"         = "govuk"
    "team"              = "govuk-search-improvement"
    "govuk_environment" = var.name
  }
}

# Required to be able to manage resources using Terraform in the environment-specific module(s)
resource "google_project_service" "cloudresourcemanager_service" {
  project                    = google_project.environment_project.project_id
  service                    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

# Required to set up service accounts and manage dynamic credentials
resource "google_project_service" "iam_service" {
  project                    = google_project.environment_project.project_id
  service                    = "iam.googleapis.com"
  disable_dependent_services = true
}

# Required to manage dynamic credentials
resource "google_project_service" "iamcredentials_service" {
  project                    = google_project.environment_project.project_id
  service                    = "iamcredentials.googleapis.com"
  disable_dependent_services = true
}

# Required to manage dynamic credentials
resource "google_project_service" "sts_service" {
  project                    = google_project.environment_project.project_id
  service                    = "sts.googleapis.com"
  disable_dependent_services = true
}

data "tfe_oauth_client" "github" {
  organization     = var.tfc_organization_name
  service_provider = "github"
}

resource "tfe_workspace" "environment_workspace" {
  name        = "search-api-v2-${var.name}"
  project_id  = var.tfc_project.id
  description = "Provisions search-api-v2 Discovery Engine resources for the ${var.display_name} environment"
  tag_names   = ["govuk", "search-api-v2", "search-api-v2-${var.terraform_module}", var.name]

  source_name = "search-v2-infrastructure meta module"
  source_url  = "https://github.com/alphagov/search-v2-infrastructure/tree/main/terraform/meta"

  execution_mode    = "remote"
  working_directory = "terraform/${var.terraform_module}"
  auto_apply        = true

  file_triggers_enabled = true
  trigger_patterns = [
    "/terraform/${var.terraform_module}/**/*.tf",
    "/terraform/modules/**/*.tf"
  ]

  vcs_repo {
    identifier     = "alphagov/search-v2-infrastructure"
    branch         = "main"
    oauth_token_id = data.tfe_oauth_client.github.oauth_token_id
  }
}

data "tfe_variable_set" "aws_credentials" {
  name  = "aws-credentials-${var.name}"
  count = var.has_deployed_service_in_aws ? 1 : 0
}

resource "tfe_workspace_variable_set" "aws_workspace_credentials" {
  variable_set_id = data.tfe_variable_set.aws_credentials[0].id
  workspace_id    = tfe_workspace.environment_workspace.id

  count = var.has_deployed_service_in_aws ? 1 : 0
}

resource "tfe_variable" "gcp_project_id" {
  workspace_id = tfe_workspace.environment_workspace.id
  category     = "terraform"
  description  = "The GCP project ID for the ${var.display_name} environment"

  key       = "gcp_project_id"
  value     = google_project.environment_project.project_id
  sensitive = false
}

# Set up Workload Identity Federation between Terraform Cloud and GCP
# see https://github.com/hashicorp/terraform-dynamic-credentials-setup-examples
resource "google_iam_workload_identity_pool" "tfc_pool" {
  project                   = google_project.environment_project.project_id
  workload_identity_pool_id = "terraform-cloud-id-pool"

  display_name = "Terraform Cloud ID Pool"
  description  = "Pool to enable access to project resources for Terraform Cloud"
}

resource "google_iam_workload_identity_pool_provider" "tfc_provider" {
  project                            = google_project.environment_project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.tfc_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "terraform-cloud-provider-oidc"

  display_name = "Terraform Cloud OIDC Provider"
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

  attribute_condition = "assertion.sub.startsWith(\"organization:${var.tfc_organization_name}:project:${var.tfc_project.name}:workspace:${tfe_workspace.environment_workspace.name}\")"
}

resource "google_service_account" "tfc_service_account" {
  project = google_project.environment_project.project_id

  account_id   = "tfc-service-account"
  display_name = "Terraform Cloud Service Account"
  description  = "Used by Terraform Cloud to manage resources in this project through Workload Identity Federation"
}

resource "google_service_account_iam_member" "tfc_service_account_member" {
  service_account_id = google_service_account.tfc_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool.name}/*"
}

resource "google_project_iam_member" "tfc_project_member" {
  project = google_project.environment_project.project_id

  role   = "roles/owner"
  member = "serviceAccount:${google_service_account.tfc_service_account.email}"
}

resource "tfe_variable" "enable_gcp_provider_auth" {
  workspace_id = tfe_workspace.environment_workspace.id

  key      = "TFC_GCP_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable Workload Identity Federation on GCP"
}

resource "tfe_variable" "tfc_gcp_workload_provider_name" {
  workspace_id = tfe_workspace.environment_workspace.id

  key      = "TFC_GCP_WORKLOAD_PROVIDER_NAME"
  value    = google_iam_workload_identity_pool_provider.tfc_provider.name
  category = "env"

  description = "The workload provider name to authenticate against on GCP"
}

resource "tfe_variable" "tfc_gcp_service_account_email" {
  workspace_id = tfe_workspace.environment_workspace.id

  key      = "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL"
  value    = google_service_account.tfc_service_account.email
  category = "env"

  description = "The GCP service account email runs will use to authenticate"
}
