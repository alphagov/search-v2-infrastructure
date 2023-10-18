## Prerequisites
### Google Cloud Platform
This Terraform configuration operates on a per-project level in GCP, which means some prior manual
setup is required before the configuration can be applied. For an environment named `example`, you
will need the following items set up:
- A Google Cloud Platform project (`search-api-v2-example`) with billing enabled
- A service account within the project (`search-api-v2-example-tf`)
  - _TODO: List roles/permissions required for service account_

> **Note**
> In addition, Vertex AI Search currently (October 2023) requires an extra step of manually
> accepting terms and conditions through the Console UI that cannot be performed programatically,
> and API calls will fail until this is done. We expect this to change in the near future.

### Terraform Cloud
For an environment named `example`, you will need the following items set up:
- A workspace (`search-v2-infrastructure-example`) in the `govuk-search-api-v2` project, with the
  following variables:
  - `GOOGLE_CREDENTIALS` environment variable configured to the GCP project's service account
  credentials from above (see [Google provider documentation][google_provider_docs])
  - `gcp_project_id` Terraform variable set to the GCP project name (`search-api-v2-example`)

## Terraform configuration files
- `main.tf`: General Terraform and provider configuration and activates the required GCP APIs
  (prerequisite for other resources)
- `discovery_engine.tf`: Sets up Discovery Engine resources
- `service_accounts.tf`: Sets up service accounts for `search-api-v2` to access Discovery Engine

> **Note**
> The Discovery Engine resources are managed through the [RestAPI provider][restapi_provider_docs]
> due to the Google provider not offering first party Terraform resources yet (as of October 2023).

[google_provider_docs]: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#using-terraform-cloud-as-the-backend
[restapi_provider_docs]: https://registry.terraform.io/providers/Mastercard/restapi/latest
[search-api-v2-repo]: https://github.com/alphagov/search-api-v2
