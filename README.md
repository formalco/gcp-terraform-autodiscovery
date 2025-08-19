# Terraform GCP Vendor Access

## Usage

Configure your project first using:

```bash
gcloud config set project [PROJECT_ID]
```

Launch the deployment using the `launch.sh` script with the following required flags:

```bash

chmod +x launch.sh


./launch.sh --account_id <ACCOUNT_ID> --role_name <ROLE_NAME> --project_id <PROJECT_ID> --integration_id <INTEGRATION_ID> --callbackUri <CALLBACK_URI>
```
