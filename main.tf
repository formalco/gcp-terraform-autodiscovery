provider "google" {
  project = var.project_id
}

# Lookup current project
data "google_project" "project" {
  project_id = var.project_id
}

# Reference an existing Workload Identity Pool (created in launch.sh if missing)
data "google_iam_workload_identity_pool" "vendor_pool" {
  project                    = var.project_id
  workload_identity_pool_id = "vendor-pool"
}

locals {
  wip_id = data.google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id
}

# Create a GCP service account per integration (based on integration_id)
resource "google_service_account" "vendor_sa" {
  account_id   = "vendor-accessor-${var.integration_id}"
  display_name = "Vendor SA for IAM role ${var.vendor_aws_iam_role_name}"
}

# Grant GKE viewer role to the GCP service account
resource "google_project_iam_member" "gke_viewer" {
  project = var.project_id
  role    = "roles/container.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}

# Create the shared AWS Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  project                             = var.project_id
  workload_identity_pool_id          = local.wip_id
  workload_identity_pool_provider_id = "aws-provider"
  display_name                        = "Vendor AWS provider"
  aws {
    account_id = var.vendor_aws_account_id
  }
}

# IAM binding to allow the AWS IAM role to impersonate the GCP SA
resource "google_service_account_iam_member" "impersonation" {
  service_account_id = google_service_account.vendor_sa.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${local.wip_id}/attribute.aws_role/arn:aws:iam::${var.vendor_aws_account_id}:role/${var.vendor_aws_iam_role_name}"
}
