# search-v2-infrastructure
IaC definitions for GOV.UK Search v2

This repository contains Terraform resource definitions to provision Google Cloud's Vertex AI Search
(also previously known as "Gen App Builder" or in the APIs as "Discovery Engine") for use as a
search engine for GOV.UK through [search-api-v2](https://github.com/alphagov/search-api-v2), and to
set up a data pipeline for analytics events to feed into the search engine model.

To that end, the following modules are part of this repository:
- [`terraform/meta`](terraform/meta/): Bootstrap Terraform Cloud project/workspaces, GCP projects,
  and workload federation between the two (applied locally with Terraform Cloud state)
- [`terraform/full_environment`](terraform/full_environment/): Set up Discovery Engine resources,
  service accounts and keys, and AWS Secrets Manager secrets consumed by the Kubernetes platform for
  an individual environment for `search-api-v2` (integration, staging, production)
- [`terraform/dev_environment`](terraform/dev_environment/): Sets up a reduced environment with only
  Discovery Engine resources for local development use
- [`terraform/modules/google_discovery_engine_restapi`](terraform/modules/google_discovery_engine_restapi/):
  A helper module to abstract deployment of Discovery Engine resources through the REST API provider
  (as there are no first party Terraform resources available in the Google provider yet)

## Working on this repository
The workspace can be run as a [devcontainer](https://containers.dev/), which includes `terraform`
and `gcloud` CLI tooling enabling log in to these providers. This is useful for working on and
applying the [`terraform/meta`](terraform/meta/) module, which is intended to be run locally by an
engineer with the required Google and Terraform Cloud access to bootstrap the initial set of
resources. You can also run plans for other modules locally.

> **Warning**
> Gitignored `.terraform.credentials.d` and `.google.credentials.d` directories are included in the
> repository, which are mounted into the devcontainer's home folder for `terraform login`/`gcloud
> login` to store credentials into (so they persist across container rebuilds). These directories
> will contain sensitive information, so do not stop them being gitignored or force any files within
> to be checked in.
