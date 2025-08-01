variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "vendor_aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vendor_aws_iam_role_name" {
  description = "AWS IAM role name to allow impersonation"
  type        = string
}

variable "integration_id" {
  description = "Integration ID used for uniquely naming the GCP service account"
  type        = string
}
