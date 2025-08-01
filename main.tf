variable "project_id" {}
variable "vendor_aws_account_id" {}
variable "vendor_aws_iam_role_name" {}

provider "google" {
  project = var.project_id
}

resource "google_service_account" "vendor_sa" {
  account_id   = "vendor-accessor"
  display_name = "Service account for vendor Temporal worker"
}

resource "google_project_iam_member" "gke_viewer" {
  role   = "roles/container.viewer"
  member = "serviceAccount:${google_service_account.vendor_sa.email}"
}

resource "google_iam_workload_identity_pool" "vendor_pool" {
  workload_identity_pool_id = "vendor-pool"
  display_name              = "Vendor Federation Pool"
  project                   = var.project_id
}

resource "google_iam_workload_identity_pool_provider" "aws_provider" {
  workload_identity_pool_id = google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id
  provider_id               = "aws-provider"
  display_name              = "Vendor AWS provider"
  aws {
    account_id = var.vendor_aws_account_id
  }
}

resource "google_service_account_iam_binding" "impersonation" {
  service_account_id = google_service_account.vendor_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id}/attribute.aws_role/arn:aws:iam::${var.vendor_aws_account_id}:role/${var.vendor_aws_iam_role_name}"
  ]
}

data "google_project" "project" {
  project_id = var.project_id
}
