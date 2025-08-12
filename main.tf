provider "google" {
  project = var.project_id
}

data "google_project" "project" {
  project_id = var.project_id
}

# Enable the Google Kubernetes Engine API
resource "google_project_service" "gke_api" {
  project = var.project_id
  service = "container.googleapis.com"

  # Optional: Disabling the service when the resource is destroyed is often
  # not desired for core services like GKE. Setting this to false prevents
  # the API from being disabled if you run 'terraform destroy'.
  disable_on_destroy = false
}

# Enable the Identity and Access Management (IAM) API
resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud SQL API
resource "google_project_service" "sql_api" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud Spanner API
resource "google_project_service" "spanner_api" {
  project = var.project_id
  service = "spanner.googleapis.com"
  disable_on_destroy = false
}

# Enable the Compute Engine API
resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud Run API
resource "google_project_service" "run_api" {
  project = var.project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
}

# Enable the BigQuery API
resource "google_project_service" "bigquery_api" {
  project = var.project_id
  service = "bigquery.googleapis.com"
  disable_on_destroy = false
}

# Enable the Cloud Storage API
resource "google_project_service" "storage_api" {
  project = var.project_id
  service = "storage.googleapis.com"
  disable_on_destroy = false
}

locals {
  # Clean integration ID for naming resources
  cleaned_integration_id = replace(var.integration_id, "_", "-")

  # Workload Identity Pool ID (≤32 chars) - unique per integration
  wip_id = substr("pool-${local.cleaned_integration_id}", 0, 32)

  # GCP service account ID (≤30 chars, must match regex)
  sa_id = substr("sa-${local.cleaned_integration_id}", 0, 30)

  # Display name (≤32 chars)
  pool_display_name = substr("Integration ${local.cleaned_integration_id}", 0, 32)
}

# Create Workload Identity Pool
resource "google_iam_workload_identity_pool" "vendor_pool" {
  project                    = var.project_id
  workload_identity_pool_id = local.wip_id
  display_name              = local.pool_display_name
  
  depends_on = [google_project_service.iam_api]
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
    
    # Add the attribute_mapping block right here, inside this resource
    attribute_mapping = {
      "google.subject"       = "assertion.arn"
      "attribute.aws_role"   = "assertion.arn.extract('assumed-role/{role}/')"
      "attribute.account_id" = "assertion.account"
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

  member = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.vendor_pool.workload_identity_pool_id}/attribute.aws_role/${var.vendor_aws_iam_role_name}"
}

# Grant GKE viewer permissions to the GCP SA
resource "google_project_iam_member" "gke_viewer" {
  project = var.project_id
  role    = "roles/container.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}

# Grant Cloud SQL viewer permissions
resource "google_project_iam_member" "cloud_sql_viewer" {
  project = var.project_id
  role    = "roles/cloudsql.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}

# Grant Cloud Spanner viewer permissions
resource "google_project_iam_member" "cloud_spanner_viewer" {
  project = var.project_id
  role    = "roles/spanner.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}

# Grant Compute Engine viewer permissions
resource "google_project_iam_member" "compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}

# Grant Cloud Run viewer permissions
resource "google_project_iam_member" "cloud_run_viewer" {
  project = var.project_id
  role    = "roles/run.viewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}

# Grant BigQuery viewer permissions
resource "google_project_iam_member" "bigquery_viewer" {
  project = var.project_id
  role    = "roles/bigquery.metadataViewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}

# Grant Cloud Storage viewer permissions
resource "google_project_iam_member" "storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.vendor_sa.email}"
}



# Notify vendor after deployment
resource "null_resource" "notify_vendor" {
  provisioner "local-exec" {
    command = <<EOT
curl \
  -d '{
    "id": "${var.integration_id}",
    "project_id": "${var.project_id}"
  }' \
  -H "Content-Type: application/json" \
  -H "X-API-Key: APIKEY" \
  '${var.notify_endpoint}/core.v1.IntegrationCloudService/UpdateGCPCloudIntegration'
EOT
  }

  depends_on = [
    google_project_service.iam_api,
    google_project_service.gke_api,
    google_iam_workload_identity_pool.vendor_pool,
    google_iam_workload_identity_pool_provider.aws_provider,
    google_service_account.vendor_sa,
    google_service_account_iam_member.impersonation,
    google_project_iam_member.gke_viewer,
    google_project_iam_member.cloud_sql_viewer,
    google_project_iam_member.cloud_spanner_viewer,
    google_project_iam_member.compute_viewer,
    google_project_iam_member.cloud_run_viewer,
    google_project_iam_member.bigquery_viewer,
    google_project_iam_member.storage_viewer
  ]
}