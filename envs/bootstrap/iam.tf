### Assign Project Creator role to Principals

data "google_iam_policy" "role_resourcemgr_prjcreator" {
  binding {
    role = "roles/resourcemanager.projectCreator"

    members = [
      "${var.type}:${var.id1}",
      "${var.type}:${var.id2}"
    ]
  }
}

# roles/resourcemanager.projectCreator
resource "google_folder_iam_policy" "folder_project_creators" {
  folder      = "folders/${var.folder_id}"
  policy_data = data.google_iam_policy.role_resourcemgr_prjcreator.policy_data
}