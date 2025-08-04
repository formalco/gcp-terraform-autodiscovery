#!/bin/bash
set -euo pipefail

# Support command-line args or Cloud Shell vars
ACCOUNT_ID="${CLOUDSHELL_VAR_account_id:-${account_id:-}}"
ROLE_NAME="${CLOUDSHELL_VAR_role_name:-${role_name:-}}"
PROJECT_ID="${CLOUDSHELL_VAR_project_id:-${project_id:-}}"
INTEGRATION_ID="${CLOUDSHELL_VAR_integration_id:-${integration_id:-}}"
NOTIFY_ENDPOINT="${CLOUDSHELL_VAR_notify_endpoint:-${notify_endpoint:-}}"

# Accept overrides via CLI flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --account_id) ACCOUNT_ID="$2"; shift 2 ;;
    --role_name) ROLE_NAME="$2"; shift 2 ;;
    --project_id) PROJECT_ID="$2"; shift 2 ;;
    --integration_id) INTEGRATION_ID="$2"; shift 2 ;;
    --notify_endpoint) NOTIFY_ENDPOINT="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Validate required inputs
if [[ -z "$ACCOUNT_ID" || -z "$ROLE_NAME" || -z "$PROJECT_ID" || -z "$INTEGRATION_ID" || -z "$NOTIFY_ENDPOINT" ]]; then
  echo "❌ Missing required parameters. Please provide: --account_id, --role_name, --project_id, --integration_id, --notify_endpoint"
  exit 1
fi

echo "🔐 Using IAM Role: $ROLE_NAME from AWS Account: $ACCOUNT_ID"
echo "📦 Target GCP Project: $PROJECT_ID"
echo "🧩 Integration ID: $INTEGRATION_ID"
echo "🔔 Notify Endpoint: $NOTIFY_ENDPOINT"

gcloud config set project "$PROJECT_ID"

terraform init
terraform apply -auto-approve \
  -var="vendor_aws_account_id=$ACCOUNT_ID" \
  -var="vendor_aws_iam_role_name=$ROLE_NAME" \
  -var="project_id=$PROJECT_ID" \
  -var="integration_id=$INTEGRATION_ID" \
  -var="notify_endpoint=$NOTIFY_ENDPOINT"