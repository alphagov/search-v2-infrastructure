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

provider "google" {
  user_project_override = true
  # billing_project       = "policy-vetting"
}

provider "google-beta" {
  user_project_override = true
  # billing_project       = "policy-vetting"
}