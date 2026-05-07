# ─────────────────────────────────────────────────────
# Project
# ─────────────────────────────────────────────────────
variable "project_id" {
  description = "The GCP project ID where all resources will be created in this project"
  type        = string
}

variable "region" {
  description = "The GCP region for all resources."
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "List of availability zones for the GKE cluster (multi-zone node pool)."
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

# ─────────────────────────────────────────────────────
# Cluster
# ─────────────────────────────────────────────────────
variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
  default     = "gke-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes minimum master version. Use 'latest' to follow the release channel."
  type        = string
  default     = "latest"
}

# ─────────────────────────────────────────────────────
# Networking
# ─────────────────────────────────────────────────────
variable "network_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "gke-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet."
  type        = string
  default     = "gke-subnet"
}

variable "subnet_cidr" {
  description = "Primary CIDR range for the subnet (nodes)."
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR range for pods (VPC-native / alias IPs)."
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR range for Kubernetes services."
  type        = string
  default     = "10.30.0.0/20"
}

variable "master_cidr" {
  description = "CIDR block (/28) for the GKE control plane (must not overlap with other ranges)."
  type        = string
  default     = "172.16.0.0/28"
}

# ─────────────────────────────────────────────────────
# Private Cluster
# ─────────────────────────────────────────────────────
variable "enable_private_nodes" {
  description = "If true, nodes only have private IP addresses (recommended)."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "If true, the master API is only accessible on the private IP."
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "CIDR blocks allowed to reach the Kubernetes API server."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All — restrict this in production"
    }
  ]
}

# ─────────────────────────────────────────────────────
# Node Pool
# ─────────────────────────────────────────────────────
variable "node_machine_type" {
  description = "Compute Engine machine type for each node."
  type        = string
  default     = "e2-standard-2"
}

variable "node_disk_size_gb" {
  description = "Boot disk size in GB per node."
  type        = number
  default     = 50
}

variable "node_disk_type" {
  description = "Boot disk type: pd-standard | pd-ssd | pd-balanced."
  type        = string
  default     = "pd-standard"
}

variable "initial_node_count" {
  description = "Initial node count per zone when the node pool is created."
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum nodes per zone for cluster autoscaler."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum nodes per zone for cluster autoscaler."
  type        = number
  default     = 3
}

# ─────────────────────────────────────────────────────
# Labels
# ─────────────────────────────────────────────────────
variable "labels" {
  description = "Labels applied to all resources."
  type        = map(string)
  default = {
    environment = "dev"
    managed-by  = "terraform"
  }
}
