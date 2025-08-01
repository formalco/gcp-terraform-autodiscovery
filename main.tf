provider "google" {
  project = var.project_id
}

# Lookup current project
data "google_project" "project" {
  project_id = var.project_id
}

# Create or reuse service account
resource "google_service_account" "vendor_sa" {
  account_id   = "vendor-accessor"
  display_name = "Service account for vendor Temporal worker"
}

# Add GKE viewer role to the service account
resource "google_project_iam_member" "gke_viewer" {
  project = var.project_id
  role    = "roles/container.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}

# Create Workload Identity Pool (idempotent)
resource "google_iam_workload_identity_pool" "vendor_pool" {
  workload_identity_pool_id = "vendor-pool"
  display_name              = "Vendor Federation Pool"
  project                   = var.project_id
}

# Create Workload Identity Provider (linked to vendor's AWS account)
resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  project                             = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "aws-provider"
  display_name                        = "Vendor AWS provider"

  aws {
    account_id = var.vendor_aws_account_id
  }
}

# Grant impersonation permission to the AWS IAM role
resource "google_service_account_iam_member" "impersonation" {
  service_account_id = google_service_account.vendor_sa.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id}/attribute.aws_role/arn:aws:iam::${var.vendor_aws_account_id}:role/${var.vendor_aws_iam_role_name}"
}
