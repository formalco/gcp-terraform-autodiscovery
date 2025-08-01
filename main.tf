provider "google" {
  project = var.project_id
}

data "google_project" "project" {
  project_id = var.project_id
}

# Clean and truncate the integration ID
locals {
  cleaned_integration_id = substr("int-${replace(var.integration_id, "_", "-")}", 0, 15)
  wip_id                 = "vendor-pool-${local.cleaned_integration_id}"
  sa_id                  = substr("vendor-${replace(var.integration_id, "_", "-")}", 0, 30)
}

# Create a unique Workload Identity Pool per integration
resource "google_iam_workload_identity_pool" "vendor_pool" {
  project                   = var.project_id
  workload_identity_pool_id = local.wip_id
  display_name             = "Federation Pool for ${var.integration_id}"
}

# Create a Workload Identity Provider for the AWS account
resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  project                             = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "aws-provider"
  display_name                        = "Vendor AWS provider"
  aws {
    account_id = var.vendor_aws_account_id
  }
}

# Create a GCP service account per integration
resource "google_service_account" "vendor_sa" {
  account_id   = local.sa_id
  display_name = "Vendor SA for IAM role ${var.vendor_aws_iam_role_name}"
}

# Allow the AWS IAM role to impersonate the GCP service account
resource "google_service_account_iam_member" "impersonation" {
  service_account_id = google_service_account.vendor_sa.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id}/attribute.aws_role/arn:aws:iam::${var.vendor_aws_account_id}:role/${var.vendor_aws_iam_role_name}"
}

# Grant the GCP SA permissions to read GKE clusters
resource "google_project_iam_member" "gke_viewer" {
  project = var.project_id
  role    = "roles/container.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}