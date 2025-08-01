#!/bin/bash
set -euo pipefail

ACCOUNT_ID="${CLOUDSHELL_VAR_account_id:-${account_id:-}}"
ROLE_NAME="${CLOUDSHELL_VAR_role_name:-${role_name:-}}"
PROJECT_ID="${CLOUDSHELL_VAR_project_id:-${project_id:-}}"
INTEGRATION_ID="${CLOUDSHELL_VAR_integration_id:-${integration_id:-default}}"

if [[ -z "$ACCOUNT_ID" || -z "$ROLE_NAME" || -z "$PROJECT_ID" ]]; then
  echo "❌ Missing required parameters: account_id, role_name, or project_id"
  exit 1
fi

echo "🔐 Using IAM Role: $ROLE_NAME from AWS Account: $ACCOUNT_ID"
echo "📦 Target GCP Project: $PROJECT_ID"

# Check if the Workload Identity Pool exists
EXISTING_POOL=$(gcloud iam workload-identity-pools describe vendor-pool \
  --project="$PROJECT_ID" \
  --location="global" \
  --format="value(name)" 2>/dev/null || true)

if [[ -z "$EXISTING_POOL" ]]; then
  echo "🛠️ Creating Workload Identity Pool 'vendor-pool'..."
  gcloud iam workload-identity-pools create vendor-pool \
    --project="$PROJECT_ID" \
    --location="global" \
    --display-name="Vendor Federation Pool"
else
  echo "✅ Workload Identity Pool 'vendor-pool' already exists."
fi

terraform init
terraform apply -auto-approve \
  -var="vendor_aws_account_id=$ACCOUNT_ID" \
  -var="vendor_aws_iam_role_name=$ROLE_NAME" \
  -var="project_id=$PROJECT_ID" \
  -var="integration_id=$INTEGRATION_ID"
