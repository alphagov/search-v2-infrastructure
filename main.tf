terraform {
  cloud {
    organization = "govuk"
    workspaces {
      name = "search-v2-infrastructure-integration"
    }
  }

  required_version = "~> 1.6"
}
