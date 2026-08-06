Enforce Encryption for New Resources (AWS) — guidance and Terraform snippets

Purpose
- Provide guardrails to ensure new cloud resources are created with encryption enabled by default.
- Offer examples for monitoring (AWS Config) and active enforcement (IAM/SCP) to prevent unencrypted resource creation.

What this includes
- scripts/terraform_enforce_encryption_aws.tf: Terraform examples for an AWS Config rule and an IAM policy document to deny unencrypted resource creation.

Recommended deployment steps
1. Create CMKs first (use scripts/terraform_kms_aws.tf) and share CMK ARN with infra modules.
2. Add S3 module defaults to create buckets with server-side encryption enabled (SSE-KMS with CMK alias or provider-managed keys).
3. Deploy AWS Config managed rules (like S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED) in each account/region to detect non-compliant resources.
4. After verifying monitoring & alerts, enforce via IAM deny policies or Organizations SCPs to prevent unencrypted resource creation.
5. Update CI/CD IaC linters (e.g., tfsec, checkov, or custom pre-commit hooks) to flag missing encryption settings before merge.

Testing and rollout
- First deploy to a staging account and monitor Config compliance for 1–2 weeks.
- Create an exceptions process for legacy workloads needing migration.
- Only after confidence, apply deny policies (SCP/IAM) cautiously and during maintenance windows.

Operational notes
- Terraform state and S3/backend storage must themselves be protected (state bucket encryption, restricted access).
- Logging: ensure CloudTrail and Config delivery channels are configured before enforcement to avoid blind spots.

Next work to do (recommended)
- Create Terraform module wrappers in infra/modules for S3, RDS, EBS with kms_key_id parameter and default to project CMK alias.
- Add pre-commit IaC checks (tfsec/checkov) to the repo to catch missing encryption configurations during PRs.
