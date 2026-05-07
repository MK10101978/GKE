# GKE Cluster with Terraform — Step-by-Step Guide

## Project Structure

```
GKE/
├── versions.tf        # Terraform + provider version constraints
├── services.tf        # Required GCP API enablement
├── main.tf            # Provider configuration
├── variables.tf       # All variable declarations
├── vpc.tf             # VPC, subnet, Cloud Router, Cloud NAT, firewall
├── gke.tf             # Service account, GKE cluster, node pool
├── outputs.tf         # Useful output values
└── terraform.tfvars   # Your variable values (edit this file)
```

---

## Architecture Overview

```
GCP Project
└── VPC (gke-vpc)
    └── Subnet (10.10.0.0/20)
        ├── Secondary range: pods     (10.20.0.0/16)
        └── Secondary range: services (10.30.0.0/20)
            └── GKE Regional Cluster
                ├── Control Plane (172.16.0.0/28) — private
                └── Node Pool (e2-standard-2, autoscaling 1–3/zone)
    └── Cloud Router + Cloud NAT  (outbound internet for private nodes)
```

**Key features enabled:**
- Private nodes (no public IPs on worker VMs)
- VPC-native / alias IP networking
- Workload Identity (replaces node-level service account key files)
- Dataplane V2 (eBPF — built-in NetworkPolicy, no Calico needed)
- Cluster Autoscaler
- Shielded VMs (Secure Boot + vTPM)
- Cloud Logging + Cloud Monitoring
- REGULAR release channel (auto patch/minor upgrades)

---

## Prerequisites

| Tool | Minimum version | Install |
|------|----------------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.5.0 | `winget install HashiCorp.Terraform` |
| [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) | latest | `winget install Google.CloudSDK` |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | latest | `gcloud components install kubectl` |

---

## Step-by-Step Instructions

### Step 1 — Authenticate with Google Cloud

```powershell
# Log in with your Google account
gcloud auth login

# Set application-default credentials (used by Terraform)
gcloud auth application-default login

# Confirm your active account
gcloud auth list
```

---

### Step 2 — Create or Select a GCP Project

```powershell
# List existing projects
gcloud projects list

# OR create a new project
gcloud projects create my-gke-project --name="My GKE Project"

# Set the active project
gcloud config set project YOUR_PROJECT_ID
```

---

### Step 3 — Configure `terraform.tfvars`

Open [terraform.tfvars](terraform.tfvars) and set at minimum:

```hcl
project_id = "YOUR_ACTUAL_PROJECT_ID"
```

Adjust region, machine type, node counts, and CIDR ranges as needed.

**Tip — production hardening:** narrow down `master_authorized_networks` to your
office/VPN IP instead of `0.0.0.0/0`.

---

### Step 4 — Initialize Terraform

```powershell
cd "c:\Mandar\Learning\GCP\TFE\GKE"

terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

---

### Step 5 — Review the Execution Plan

```powershell
terraform plan
```

This shows you every resource that will be created — nothing is applied yet.
The plan now includes API enablement resources first, followed by network,
service account, IAM bindings, cluster, and node pool.

---

### Step 6 — Apply the Configuration

```powershell
terraform apply
```

Type `yes` when prompted.

> **First apply takes longer** because Terraform enables the required GCP APIs
> and then builds the infrastructure. Total time is usually **10–20 minutes**.
> The node pool is provisioned after
> the control plane is ready.

---

### Step 7 — Configure `kubectl`

After apply completes, run the output command:

```powershell
# Terraform prints this for you:
terraform output kubectl_config_command

# Then run it, e.g.:
gcloud container clusters get-credentials my-gke-cluster --region us-central1 --project YOUR_PROJECT_ID
```

Verify access:

```powershell
kubectl get nodes
kubectl get namespaces
```

---

### Step 8 — Deploy a Test Workload (Optional)

```powershell
kubectl create deployment hello --image=gcr.io/google-samples/hello-app:1.0 --replicas=2
kubectl expose deployment hello --type=LoadBalancer --port=80 --target-port=8080
kubectl get service hello --watch   # wait for EXTERNAL-IP
```

---

### Step 9 — Clean Up (When Done)

```powershell
terraform destroy
```

Type `yes` to delete **all** resources. This avoids ongoing GCP charges.

---

## Common Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `project_id` | *(required)* | Your GCP project ID |
| `region` | `us-central1` | Cluster region |
| `cluster_name` | `gke-cluster` | Name of the cluster |
| `node_machine_type` | `e2-standard-2` | VM size per node |
| `min_node_count` | `1` | Autoscaler floor (per zone) |
| `max_node_count` | `3` | Autoscaler ceiling (per zone) |
| `enable_private_nodes` | `true` | Nodes without public IPs |
| `enable_private_endpoint` | `false` | Hide API server from internet |

---

## Troubleshooting

| Problem | Likely cause | Fix |
|---------|-------------|-----|
| `Error 403: Required APIs not enabled` | API enablement still propagating | Wait 1-2 minutes and re-run `terraform apply` |
| `Error: Quota exceeded` | CPU/IP quota | Request quota increase in GCP Console |
| `kubectl: connection refused` | Credentials not configured | Re-run Step 7 |
| `googleapi: Error 400: Master version ... not found` | Invalid k8s version | Set `kubernetes_version = "latest"` |
| Node pool stuck `PROVISIONING` | NAT not ready | Wait; NAT starts after subnet creation |

---

## Security Notes

- Node VMs have **no public IP** (`enable_private_nodes = true`).
- The node service account uses **least-privilege** IAM roles.
- Legacy metadata endpoints are **disabled** on nodes.
- **Workload Identity** is enabled — pods use short-lived tokens, not key files.
- **Shielded Nodes** protect against rootkit/bootkit attacks.
- Restrict `master_authorized_networks` to known IPs before going to production.
