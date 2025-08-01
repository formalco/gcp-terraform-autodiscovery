variable "project_id" {
  description = "The ID of the GCP project where resources will be created"
  type        = string
}

variable "vendor_aws_account_id" {
  description = "The AWS account ID of the vendor"
  type        = string
}

variable "vendor_aws_iam_role_name" {
  description = "The name of the AWS IAM role used for impersonation"
  type        = string
}

variable "integration_id" {
  description = "The unique Formal integration ID for this deployment"
  type        = string
}

variable "pool_exists" {
  description = "Set to false to create the workload identity pool; true to use an existing one"
  type        = bool
  default     = true
}