# meta
Terraform module to bootstrap Terraform Cloud project/workspaces, GCP projects, and workload
federation between the two.

## Resources
This module sets up the following resources:
- A Terraform Cloud project
- A set of Terraform Cloud workspaces (per environment), with appropriate environment-specific
  variables (based on `environments` set variable)

## Applying this module
This module uses Terraform Cloud for remote state storage, but is intended to be run *locally* by a
user with "interactive" end-user access to both Terraform Cloud and Google Cloud Platform (so as to
not have a chicken-and-egg problem around having to manually create service accounts to manage
meta-resources like service accounts or projects).

### Authentication
Before you can use this module, you must:
- use `tf login` to authenticate to Terraform Cloud
