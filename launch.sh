#!/bin/bash
set -euo pipefail

ACCOUNT_ID="${CLOUDSHELL_VAR_account_id:-}"
ROLE_NAME="${CLOUDSHELL_VAR_role_name:-}"
PROJECT_ID="${CLOUDSHELL_VAR_project_id:-}"

if [[ -z "$ACCOUNT_ID" || -z "$ROLE_NAME" ]]; then
  echo "\n❌ Missing required parameters. Make sure the Cloud Shell link includes account_id and role_name."
  exit 1
fi

echo "\n🔐 Using IAM Role: $ROLE_NAME from AWS Account: $ACCOUNT_ID"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
if [[ -z "$PROJECT_ID" ]]; then
  echo "\n❌ GCP project is not set. Please run: gcloud config set project <PROJECT_ID>"
  exit 1
fi

terraform init
terraform apply -auto-approve \
  -var="vendor_aws_account_id=$ACCOUNT_ID" \
  -var="vendor_aws_iam_role_name=$ROLE_NAME" \
  -var="project_id=$PROJECT_ID"
