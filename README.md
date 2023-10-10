# search-v2-infrastructure
IaC definitions for GOV.UK Search v2

## Development containers
The workspace can be run as a devcontainer. A gitignored `.terraform.credentials.d` directory is
included in the repository, which is mounted into the devcontainer's home folder for `tf login` to
store Terraform Cloud tokens into (so they persist across container rebuilds). This directory will
contain sensitive information, so do not stop it being gitignored or force any files within to be
checked in.
