# ─────────────────────────────────────────────────────────────────
#  terraform.tfvars — fill in your values before running apply
# ─────────────────────────────────────────────────────────────────

# ── Project ──────────────────────────────────────────────────────
project_id = "astral-digit-488514-q1" # <-- REQUIRED: replace with your GCP project ID
region     = "us-central1"
zones      = ["us-central1-a", "us-central1-b", "us-central1-c"]

# ── Cluster ───────────────────────────────────────────────────────
cluster_name       = "my-gke-cluster"
kubernetes_version = "latest" # or pin, e.g. "1.29"

# ── Networking ────────────────────────────────────────────────────
network_name  = "gke-vpc"
subnet_name   = "gke-subnet"
subnet_cidr   = "10.10.0.0/20"  # nodes
pods_cidr     = "10.20.0.0/16"  # pods  (alias IPs — must not overlap)
services_cidr = "10.30.0.0/20"  # services
master_cidr   = "172.16.0.0/28" # control plane (/28 required)

# ── Private Cluster ───────────────────────────────────────────────
enable_private_nodes    = true  # nodes get only private IPs (recommended)
enable_private_endpoint = false # set true to hide the API server from internet

master_authorized_networks = [
  {
    cidr_block   = "0.0.0.0/0"
    display_name = "All — restrict to your IP/VPN CIDR in production"
  }
]

# ── Node Pool ─────────────────────────────────────────────────────
node_machine_type  = "e2-standard-2" # 2 vCPU / 8 GB RAM
node_disk_size_gb  = 50
node_disk_type     = "pd-standard" # pd-standard | pd-ssd | pd-balanced
initial_node_count = 1             # per zone at creation time
min_node_count     = 1             # autoscaler minimum per zone
max_node_count     = 3             # autoscaler maximum per zone

# ── Application Service Account ───────────────────────────────────
app_sa_account_id = "svc-app-deployment" # GCP service account name
wi_k8s_namespace  = "default"            # Kubernetes namespace for Workload Identity
wi_k8s_sa_name    = "app-ksa"            # Kubernetes service account name

# ── Labels ────────────────────────────────────────────────────────
labels = {
  environment = "dev"
  managed-by  = "terraform"
}
