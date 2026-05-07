locals {
  required_gcp_services = toset([
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])
}

# Enable required APIs for the project before creating any infrastructure.
resource "google_project_service" "required" {
  for_each = local.required_gcp_services

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}
