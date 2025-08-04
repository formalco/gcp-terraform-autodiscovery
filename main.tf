provider "google" {
  project = var.project_id
}

data "google_project" "project" {
  project_id = var.project_id
}

locals {
<<<<<<< Updated upstream
  # Clean and shorten integration ID for naming resources
  cleaned_integration_id = substr(replace(var.integration_id, "_", "-"), 0, 20)

  # Workload Identity Pool ID (≤32 chars)
  wip_id = "vendor-pool-${substr(local.cleaned_integration_id, 0, 15)}"

  # GCP service account ID (≤30 chars, must match regex)
  sa_id = "vendor-${substr(local.cleaned_integration_id, 0, 23)}"

  # Display name (≤32 chars)
  pool_display_name = substr("Pool for ${local.cleaned_integration_id}", 0, 32)
=======
  # Clean and truncate the integration ID
  cleaned_integration_id = substr("int-${replace(var.integration_id, "_", "-")}", 0, 15)
  integration_suffix     = substr(var.integration_id, -8, 8)

  # Use for pool ID, service account ID, and display name
  wip_id        = "vendor-pool-${local.cleaned_integration_id}"
  sa_id         = substr("vendor-${replace(var.integration_id, "_", "-")}", 0, 30)
  display_name  = "formal_integration_${local.integration_suffix}"
>>>>>>> Stashed changes
}

# Create Workload Identity Pool
resource "google_iam_workload_identity_pool" "vendor_pool" {
  project                    = var.project_id
  workload_identity_pool_id = local.wip_id
<<<<<<< Updated upstream
  display_name              = local.pool_display_name
=======
  display_name              = local.display_name
>>>>>>> Stashed changes
}

# Create Workload Identity Provider for AWS
resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  project                             = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "aws-provider"
  display_name                        = "Vendor AWS provider"
  aws {
    account_id = var.vendor_aws_account_id
  }
}

# Create GCP Service Account
resource "google_service_account" "vendor_sa" {
  account_id   = local.sa_id
  display_name = "Vendor SA for ${var.integration_id}"
}

# Allow AWS IAM role to impersonate GCP SA
resource "google_service_account_iam_member" "impersonation" {
  service_account_id = google_service_account.vendor_sa.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id}/attribute.aws_role/arn:aws:iam::${var.vendor_aws_account_id}:role/${var.vendor_aws_iam_role_name}"
}

# Grant GKE viewer permissions to the GCP SA
resource "google_project_iam_member" "gke_viewer" {
  project = var.project_id
  role    = "roles/container.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}
<<<<<<< Updated upstream
=======

# Notify vendor after deployment
resource "null_resource" "notify_vendor" {
  provisioner "local-exec" {
    command = <<EOT
curl -X POST ${var.notify_endpoint} \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "${var.project_id}",
    "integration_id": "${var.integration_id}",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }'
EOT
  }

  depends_on = [
    google_iam_workload_identity_pool.vendor_pool,
    google_iam_workload_identity_pool_provider.aws_provider,
    google_service_account.vendor_sa,
    google_service_account_iam_member.impersonation,
    google_project_iam_member.gke_viewer
  ]
}
>>>>>>> Stashed changes
