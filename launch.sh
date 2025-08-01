#!/bin/bash
set -euo pipefail

# Defaults
ACCOUNT_ID="${CLOUDSHELL_VAR_account_id:-}"
ROLE_NAME="${CLOUDSHELL_VAR_role_name:-}"
PROJECT_ID="${CLOUDSHELL_VAR_project_id:-}"
INTEGRATION_ID="${CLOUDSHELL_VAR_integration_id:-default}"
POOL_EXISTS="true"

# Parse command-line arguments (optional overrides)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --account_id) ACCOUNT_ID="$2"; shift 2 ;;
    --role_name) ROLE_NAME="$2"; shift 2 ;;
    --project_id) PROJECT_ID="$2"; shift 2 ;;
    --integration_id) INTEGRATION_ID="$2"; shift 2 ;;
    --pool_exists) POOL_EXISTS="$2"; shift 2 ;;
    *) echo "❌ Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required fields
if [[ -z "$ACCOUNT_ID" || -z "$ROLE_NAME" || -z "$PROJECT_ID" ]]; then
  echo -e "\n❌ Missing required parameters: account_id, role_name, or project_id"
  echo "👉 Pass them via environment, launch link, or command line:"
  echo "   ./launch.sh --account_id 123 --role_name abc --project_id xyz --integration_id foo"
  exit 1
fi

echo "🔐 Using IAM Role: $ROLE_NAME from AWS Account: $ACCOUNT_ID"
echo "📦 Target GCP Project: $PROJECT_ID"
echo "🧩 Integration ID: $INTEGRATION_ID"
echo "☁️  Pool exists: $POOL_EXISTS"

# Check if pool exists if pool_exists=true
if [[ "$POOL_EXISTS" == "true" ]]; then
  echo "🔍 Checking for existing workload identity pool..."
  if ! gcloud iam workload-identity-pools describe vendor-pool \
    --project="$PROJECT_ID" \
    --location="global" >/dev/null 2>&1; then
    echo "❌ Pool not found. Re-run with: --pool_exists false"
    exit 1
  else
    echo "✅ Pool exists."
  fi
else
  echo "🛠️ Creating workload identity pool 'vendor-pool'..."
  gcloud iam workload-identity-pools create vendor-pool \
    --project="$PROJECT_ID" \
    --location="global" \
    --display-name="Vendor Federation Pool"
fi

# Apply Terraform
terraform init
terraform apply -auto-approve \
  -var="vendor_aws_account_id=$ACCOUNT_ID" \
  -var="vendor_aws_iam_role_name=$ROLE_NAME" \
  -var="project_id=$PROJECT_ID" \
  -var="integration_id=$INTEGRATION_ID" \
  -var="pool_exists=$POOL_EXISTS"