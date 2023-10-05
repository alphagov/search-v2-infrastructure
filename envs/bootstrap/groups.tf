
module "grp_discoveryengine_admin" {
  source  = "terraform-google-modules/group/google"
  version = "~> 0.1"

  count = var.create_discoveryengine_groups ? 1 : 0

  id           = "discoveryengine-admin@${var.domain}"
  display_name = "discoveryengine-admin"
  description  = "Discovery Engine Admin Role"
  domain       = var.domain
}

module "grp_discoveryengine_editor" {
  source  = "terraform-google-modules/group/google"
  version = "~> 0.1"

  count = var.create_discoveryengine_groups ? 1 : 0

  id           = "discoveryengine-editor@${var.domain}"
  display_name = "discoveryengine-editor"
  description  = "Discovery Engine Editor Role"
  domain       = var.domain
}

module "grp_discoveryengine_viewer" {
  source  = "terraform-google-modules/group/google"
  version = "~> 0.1"

  count = var.create_discoveryengine_groups ? 1 : 0

  id           = "discoveryengine-viewer@${var.domain}"
  display_name = "discoveryengine-viewer"
  description  = "Discovery Engine Viewer Role"
  domain       = var.domain
}

module "grp_discoveryengine_developer" {
  source  = "terraform-google-modules/group/google"
  version = "~> 0.1"

  count = var.create_discoveryengine_groups ? 1 : 0

  id           = "discoveryengine-developer@${var.domain}"
  display_name = "discoveryengine-developer"
  description  = "Discovery Engine Developer Role"
  domain       = var.domain
}

module "grp_discoveryengine_operations" {
  source  = "terraform-google-modules/group/google"
  version = "~> 0.1"

  count = var.create_discoveryengine_groups ? 1 : 0

  id           = "discoveryengine-operations@${var.domain}"
  display_name = "discoveryengine-operations"
  description  = "Discovery Engine Operations Role"
  domain       = var.domain
}
