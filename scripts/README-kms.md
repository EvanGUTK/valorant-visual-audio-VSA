AWS KMS CMK Terraform snippet (scripts/terraform_kms_aws.tf)

Purpose
- Small example Terraform configuration to provision a customer-managed CMK (symmetric), an alias, and outputs.
- Intended as a starting point for the implement-kms todo. Adapt to your Terraform module conventions and add strict key policies.

Usage
- Copy scripts/terraform_kms_aws.tf into your infra folder, or convert to a module under infra/modules/kms.
- Update variable values (alias_name, region, description) and add a restrictive key policy.
- Ensure CloudTrail is enabled to capture KMS events and route logs to a secure S3 bucket / Log Analytics.

Recommendations
- Do not enable public or overly-broad key policies; prefer IAM roles with least privilege.
- For automated workloads (Lambda, ECS, EC2), create IAM roles with kms:Decrypt permission on the CMK.
- Use CMK alias conventions: alias/project-name/env-cmk (e.g., alias/myapp-prod-cmk).
- Use Terraform state encryption and restrict access to state storage (S3, GCS, AzBlob).

Next steps (suggested)
- Create an infra/modules/kms module with parameters for key usage (encrypt/decrypt/grant), key rotation cadence, and tagging.
- Add automated tests or a pre-apply validation to ensure no unencrypted resources are created.
