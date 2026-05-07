output "cluster_name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.primary.name
}

output "cluster_location" {
  description = "Region where the GKE cluster is deployed."
  value       = google_container_cluster.primary.location
}

output "cluster_endpoint" {
  description = "HTTPS endpoint of the Kubernetes API server."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded CA certificate of the cluster."
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "node_service_account_email" {
  description = "Email of the least-privilege service account used by GKE nodes."
  value       = google_service_account.gke_sa.email
}

output "vpc_name" {
  description = "Name of the VPC network."
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the subnet used by the cluster."
  value       = google_compute_subnetwork.subnet.name
}

output "kubectl_config_command" {
  description = "Run this command to configure kubectl for the cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}
