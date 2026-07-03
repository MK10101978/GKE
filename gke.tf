# ─────────────────────────────────────────────────────
# Dedicated Service Account for GKE nodes (least-privilege)
# ─────────────────────────────────────────────────────
resource "google_service_account" "gke_sa" {
  account_id   = "${var.cluster_name}-node-sa"
  display_name = "GKE Node SA — ${var.cluster_name}"
  project      = var.project_id

  depends_on = [google_project_service.required]
}

# Minimum IAM roles required by the GKE node agent
resource "google_project_iam_member" "gke_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "gke_sa_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "gke_sa_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"

  depends_on = [google_project_service.required]
}

# Pull images from Artifact Registry
resource "google_project_iam_member" "gke_sa_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_sa.email}"

  depends_on = [google_project_service.required]
}

# ─────────────────────────────────────────────────────
# GKE Cluster
# ─────────────────────────────────────────────────────
resource "google_container_cluster" "primary" {
  provider = google-beta

  name                = var.cluster_name
  location            = var.region # regional cluster → HA control plane
  project             = var.project_id
  deletion_protection = false

  # We manage the node pool separately; remove the default one.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # ── Kubernetes version ──────────────────────────────
  min_master_version = var.kubernetes_version == "latest" ? null : var.kubernetes_version

  # ── VPC-native (alias IP) networking ────────────────
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # ── Private cluster ──────────────────────────────────
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_cidr
  }

  # ── Master authorized networks ───────────────────────
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # ── Workload Identity ────────────────────────────────
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # ── Dataplane V2 (eBPF — includes built-in NetworkPolicy) ──
  datapath_provider = "ADVANCED_DATAPATH"

  # ── Add-ons ──────────────────────────────────────────
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  # ── Observability ────────────────────────────────────
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # ── Release channel ──────────────────────────────────
  release_channel {
    channel = "REGULAR"
  }

  # ── Maintenance window (weekends 00:00–04:00 UTC) ────
  maintenance_policy {
    recurring_window {
      start_time = "2026-01-01T00:00:00Z"
      end_time   = "2026-01-01T04:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  # ── Security ─────────────────────────────────────────
  enable_shielded_nodes = true

  resource_labels = var.labels

  lifecycle {
    ignore_changes = [
      initial_node_count,
      min_master_version,
    ]
  }

  depends_on = [
    google_project_service.required,
    google_compute_subnetwork.subnet,
    google_compute_router_nat.nat,
  ]
}

# ─────────────────────────────────────────────────────
# Node Pool
# ─────────────────────────────────────────────────────
resource "google_container_node_pool" "primary_nodes" {
  name     = "${var.cluster_name}-node-pool"
  location = var.region
  cluster  = google_container_cluster.primary.name
  project  = var.project_id

  initial_node_count = var.initial_node_count

  # ── Autoscaling ──────────────────────────────────────
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # ── Node management ──────────────────────────────────
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # ── Surge upgrades (zero downtime) ───────────────────
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  # ── Node configuration ───────────────────────────────
  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = var.node_disk_type

    service_account = google_service_account.gke_sa.email

    # cloud-platform scope covers all Google Cloud APIs (controlled by IAM)
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = var.labels

    # Shielded VM — Secure Boot + vTPM integrity monitoring
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Expose GKE metadata server to pods (Workload Identity)
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Disable legacy metadata server endpoints
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}
