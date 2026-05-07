# ─────────────────────────────────────────────────────
# VPC Network
# ─────────────────────────────────────────────────────
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id

  depends_on = [google_project_service.required]
}

# ─────────────────────────────────────────────────────
# Subnet  (primary range = nodes, 2 secondary = pods/services)
# ─────────────────────────────────────────────────────
resource "google_compute_subnetwork" "subnet" {
  name                     = var.subnet_name
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  project                  = var.project_id
  private_ip_google_access = true # allows nodes to reach Google APIs without NAT

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  depends_on = [google_project_service.required]
}

# ─────────────────────────────────────────────────────
# Cloud Router  (required by Cloud NAT)
# ─────────────────────────────────────────────────────
resource "google_compute_router" "router" {
  name    = "${var.cluster_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id

  depends_on = [google_project_service.required]
}

# ─────────────────────────────────────────────────────
# Cloud NAT  (gives private nodes outbound internet access)
# ─────────────────────────────────────────────────────
resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  depends_on = [google_project_service.required]
}

# ─────────────────────────────────────────────────────
# Firewall — allow intra-cluster traffic
# ─────────────────────────────────────────────────────
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  description = "Allow all internal traffic between nodes, pods, and services."

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.subnet_cidr,
    var.pods_cidr,
    var.services_cidr,
  ]

  depends_on = [google_project_service.required]
}
