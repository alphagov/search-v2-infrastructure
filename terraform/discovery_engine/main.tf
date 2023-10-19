terraform {
  cloud {
    organization = "govuk"
    workspaces {
      project = "govuk-search-api-v2"

      # All workspaces that relate to deployable environments have this tag set up in `meta` module
      tags = ["search-api-v2-discovery-engine"]
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.21.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.1.0"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 1.18.2"
    }
  }

  required_version = "~> 1.6"
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

provider "aws" {
  region = "eu-west-1"
}
