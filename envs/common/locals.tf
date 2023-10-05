locals {
  project = "prj-c-discoveryengine"

  services = [
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "discoveryengine.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "storage.googleapis.com"
  ]
}