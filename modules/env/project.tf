
data "google_project" "base" {
  project_id = var.project_id
  # name = "GDS-Search"
}

resource "google_project_service" "base_services" {
  for_each = toset(var.services)

  project                    = data.google_project.base.project_id
  service                    = each.value
  disable_dependent_services = true

  timeouts {
    create = "30m"
    update = "40m"
  }
}