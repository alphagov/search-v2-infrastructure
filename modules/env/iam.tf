# # Big Query
# resource "google_project_iam_binding" "bigquery_dataeditor" {
#   project = data.google_project.base.project_id
#   role    = "roles/bigquery.dataEditor"
#   members = [
#     "serviceAccount:${var.govuk_group}"
#   ]
# }

# # Discovery Engine
# resource "google_project_iam_binding" "discoveryengine_admin" {
#   project = data.google_project.base.project_id
#   role    = "roles/discoveryengine.admin"

#   members = [
#     "group:discoveryengine-admin@${var.domain}",
#     "group:discoveryengine-developer@${var.domain}"
#   ]
# }

# resource "google_project_iam_binding" "discoveryengine_editor" {
#   project = data.google_project.base.project_id
#   role    = "roles/discoveryengine.editor"
#   members = [
#     "serviceAccount:${google_service_account.user_event_pipeline.email}",
#     "serviceAccount:${google_service_account.index_manager.email}",
#     "group:discoveryengine-editor@${var.domain}"
#   ]
# }

# resource "google_project_iam_binding" "discoveryengine_viewer" {
#   project = data.google_project.base.project_id
#   role    = "roles/discoveryengine.viewer"
#   members = [
#     "serviceAccount:${google_service_account.search.email}",
#      "group:discoveryengine-viewer@${var.domain}",
#      "group:discoveryengine-developer@${var.domain}",
#      "group:discoveryengine-operations@${var.domain}"
#   ]
# }

# # # PubSub
# # resource "google_project_iam_binding" "pubsub_subscriber" {
# #   project = data.google_project.base.project_id
# #   role    = "roles/pubsub.subscriber"
# #   members = [
# #     "serviceAccount:${google_service_account.index_manager.email}"
# #   ]
# # }

# #  Operations
# resource "google_project_iam_binding" "monitoring_viewer" {
#   project = data.google_project.base.project_id
#   role    = "roles/monitoring.viewer"

#   members = [
#     "group:discoveryengine-developer@${var.domain}",
#     "group:discoveryengine-operations@${var.domain}"
#   ]
# }

# resource "google_project_iam_binding" "monitoring_editor" {
#   project = data.google_project.base.project_id
#   role    = "roles/monitoring.editor"

#   members = [
#     "group:discoveryengine-developer@${var.domain}",
#     "group:discoveryengine-operations@${var.domain}"
#   ]
# }

# resource "google_project_iam_binding" "logging_viewer" {
#   project = data.google_project.base.project_id
#   role    = "roles/logging.viewer"

#   members = [
#     "group:discoveryengine-developer@${var.domain}"
#   ]
# }

# resource "google_project_iam_binding" "service_usage_viewer" {
#   project = data.google_project.base.project_id
#   role    = "roles/serviceusage.serviceUsageViewer"

#   members = [
#     "group:discoveryengine-admin@${var.domain}",
#     "group:discoveryengine-editor@${var.domain}",
#     "group:discoveryengine-viewer@${var.domain}",
#     "group:discoveryengine-developer@${var.domain}",
#     "group:discoveryengine-operations@${var.domain}"
#   ]
# }