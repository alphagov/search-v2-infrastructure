terraform {
  cloud {
    organization = "govuk"
    workspaces {
      project = "govuk-search-api-v2"

      # All workspaces for this module have this tag set up by `meta` module
      tags = ["search-api-v2-dev_environment"]
    }
  }

  required_version = "~> 1.6"
}
