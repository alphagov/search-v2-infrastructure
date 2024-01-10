# meta
Terraform module to bootstrap Terraform Cloud project/workspaces, GCP projects, and workload
federation between the two.

## Resources
This module manages the following resources:
- A Terraform Cloud project
- A Terraform Cloud workspace for itself
- For every desired environment (dev, integration, staging, prod), through the `modules/environment`
  child module:
  - A Terraform Cloud workspace to run Terraform from the `terraform_working_directory` folder in
    this repository on VCS merges
  - A GCP project
  - Workload identity federation between the GCP project and Terraform Cloud project
  - A binding to the (existing) Terraform Cloud variable set for AWS access (except for environments
    where `has_deployed_service_in_aws` is false, i.e. dev)

## Applying this module
This module uses Terraform Cloud for remote state storage, but is intended to be run *locally* by a
user with "interactive" end-user access to both Terraform Cloud and Google Cloud Platform (so as to
not have a chicken-and-egg problem around having to manually create service accounts to manage
meta-resources like service accounts or projects).

### Authentication & configuration
Before you can use this module, you must:
- use `terraform login` to authenticate to Terraform Cloud
- use `gcloud auth application-default login` to authenticate to GCP
- specify values for `google_cloud_folder` and `google_cloud_billing_account` as parameters to
  `terraform` or through a (gitignored) `local.auto.tfvars` file

## Additional information
### Adding additional GCP quota overrides
Quota overrides on GCP are somewhat complex to set up and use inconsistent terminology between the
console UI, the REST API, and the (beta) Terraform provider. In particular, it can be somewhat
confusing to figure out the `limit` value for the `google_service_usage_consumer_quota_override`
resource (which actually corresponds to the `unit` field in the API but with different syntax), and
to find the internal (not display) name of quotas.

If you need to set up a new `google_service_usage_consumer_quota_override` resource for a Discovery
Engine project, the best way of finding out these values is to make a GET request to the
`consumerQuotaMetrics` endpoint like so:

```bash
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
"https://serviceusage.googleapis.com/v1beta1/projects/${GCP_PROJECT}/services/discoveryengine.googleapis.com/consumerQuotaMetrics" \
| jq -r '.metrics[] | "\(.displayName): \(.consumerQuotaLimits[0].metric) (\(.consumerQuotaLimits[0].unit | gsub("[1\\{\\}]";"")))"' \
| sort
```

This returns a list of available quotas by display name, complete with the necessary `metric` and
`unit` values.
