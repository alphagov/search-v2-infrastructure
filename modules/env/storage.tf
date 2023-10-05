resource "google_storage_bucket" "storage_event" {
  name     = lower("${data.google_project.base.name}-event")
  location = var.location
  project  = data.google_project.base.project_id

  force_destroy            = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket" "storage_catalog" {
  name     = lower("${data.google_project.base.name}-catalog")
  location = var.location
  project  = data.google_project.base.project_id

  force_destroy            = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket" "storage_temp" {
  name     = lower("${data.google_project.base.name}-temp")
  location = var.location
  project  = data.google_project.base.project_id

  force_destroy            = true
  public_access_prevention = "enforced"
}