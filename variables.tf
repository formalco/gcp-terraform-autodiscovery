variable "project_id" {
  type        = string
  description = "The customer's GCP project ID"
}

variable "vendor_aws_account_id" {
  type        = string
  description = "Vendor's AWS account ID that owns the IAM Role"
}

variable "vendor_aws_iam_role_name" {
  type        = string
  description = "The name of the IAM Role that will impersonate the GCP SA"
}

