# ─────────────────────────────────────────────────────
# Application Service Account (Workload Identity)
# ─────────────────────────────────────────────────────
resource "google_service_account" "app_sa" {
  account_id   = var.app_sa_account_id
  display_name = "App SA — ${var.app_sa_account_id}"
  project      = var.project_id

  depends_on = [google_project_service.required]
}

# ─────────────────────────────────────────────────────
# IAM Role Bindings
# ─────────────────────────────────────────────────────
resource "google_project_iam_member" "app_sa_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_project_iam_member" "app_sa_bigquery_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_project_iam_member" "app_sa_cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_project_iam_member" "app_sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_project_iam_member" "app_sa_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

resource "google_project_iam_member" "app_sa_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# ─────────────────────────────────────────────────────
# Workload Identity Binding
# Allows the Kubernetes SA to impersonate this GCP SA
# ─────────────────────────────────────────────────────
resource "google_service_account_iam_member" "app_sa_workload_identity" {
  service_account_id = google_service_account.app_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.wi_k8s_namespace}/${var.wi_k8s_sa_name}]"
}
