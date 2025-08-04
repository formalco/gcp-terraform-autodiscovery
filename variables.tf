variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "vendor_aws_account_id" {
  description = "The AWS account ID of the vendor"
  type        = string
}

variable "vendor_aws_iam_role_name" {
  description = "The name of the AWS IAM role to federate from"
  type        = string
}

variable "integration_id" {
  description = "Unique ID for the integration"
  type        = string
}

variable "notify_endpoint" {
  description = "The endpoint URL to notify after deployment completion"
  type        = string
}