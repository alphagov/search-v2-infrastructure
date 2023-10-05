terraform {
  required_version = ">= 0.13"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "< 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "< 5.0"
    }
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  lower   = true
  upper   = false
}

resource "google_project" "common" {
  name            = local.project
  project_id      = "${local.project}-${random_string.suffix.result}"
  folder_id       = var.folder_id
  billing_account = var.billing_id

  #   depends_on = [
  #     google_folder_iam_policy.folder_project_creators
  #   ]
}

resource "google_project_service" "common_services" {
  for_each = toset(local.services)

  project                    = google_project.common.id
  service                    = each.value
  disable_dependent_services = true

  timeouts {
    create = "30m"
    update = "40m"
  }
}