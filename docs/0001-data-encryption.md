# ADR 0001: Data encryption at rest & in transit

Status: proposed
Date: 2026-08-06
Authors: Principal Systems Architect (agent)

Assumptions
- Repository is an application/service codebase needing production architecture guidance.
- Target is cloud-hosted and managed services are permitted.
- No special regulatory constraints (PCI/HIPAA) apply unless stated otherwise.

Context
- Requirement: Protect all sensitive and regulated data in transit and at rest across storage, databases, backups, and secrets.
- Constraints: Cloud-hosted; managed services allowed; aim to minimize operational burden while enabling strong control for sensitive datasets.
- Non-functional priorities: confidentiality, availability, maintainability, minimal performance impact.

Decision
Adopt cloud-managed KMS (customer-managed keys/CMEK where feasible) as the primary key management approach, combined with application-level envelope encryption for sensitive payloads and secrets stored in managed Secrets Manager (AWS Secrets Manager / GCP Secret Manager / Azure Key Vault). Use per-object data keys (generated via KMS) encrypted by CMKs; enable automatic CMK rotation where available and implement a documented manual rotation procedure for more frequent rotations. Provider-managed keys will be the default; BYOK/custodian-imported keys are supported for regulated datasets (policy choice to be confirmed).

Consequences
- Security: Strong cryptographic protection with centralized key lifecycle & auditability.
- Operational: Moderate setup & migration effort; lower ongoing operational burden if provider-managed keys are used; higher if BYOK/HSM import chosen.
- Performance: Slight latency added on first-time key generation/decryption but mitigated via envelope encryption and local caching of decrypted data keys as appropriate.
- Cost: KMS per-key and per-request costs; secrets manager charges per secret/version; migration re-encryption compute/storage costs.
- Migration effort: Non-zero; requires discovery + phased re-encryption for existing data stores; supports low-risk cutovers with snapshots/replicas.
- Risks: Misconfigured IAM/policies may cause service outages; key compromise requires coordinated rotation & possible data re-encryption.

Alternatives considered
1) Provider-managed keys only (low operational burden)
   - Pros: Simple, low-cost operations, integrated audit, auto-rotation features.
   - Cons: Less customer control; not acceptable if strict BYOK / compliance required.
2) BYOK / Imported HSM keys
   - Pros: Strongest customer control of key material, better for some compliance regimes.
   - Cons: Higher cost & complexity (HSM operations, import workflows), increased operational burden, potential availability risk if import process mismanaged.
3) Third-party Vault (HashiCorp Vault) with HSM-backed storage
   - Pros: Centralized cross-cloud key & secret management, flexible policies.
   - Cons: Significant operational overhead unless using managed Vault offerings.
4) App-managed encryption keys (in-app KMS)
   - Pros: Full control, no provider lock-in.
   - Cons: High risk, complex to do correctly, poor auditability.

Recommended approach (summary)
- Default: Provider-managed CMKs (cloud KMS) + envelope encryption for application-level data; store secrets in provider Secrets Manager/Key Vault.
- Support BYOK/CMEK import for specific regulated datasets when policy requires it (single policy choice to confirm).
- Enforce encryption-by-default for new resources (S3/GCS/Azure Blob, EBS/Azure disks, managed DBs).
- For high-volume ephemeral data, prefer SSE (service-managed) plus envelope encryption as needed to reduce KMS API calls.

KMS & envelope encryption details
- Pattern:
  1. App calls KMS GenerateDataKey to get a plaintext data key and encrypted (ciphertext) data key.
  2. App uses plaintext data key to encrypt payload locally (AES-GCM), stores encrypted payload + encrypted data key (ciphertext blob).
  3. On read, app requests KMS Decrypt on the encrypted data key (or caches plaintext data key securely for TTL) to obtain plaintext data key, decrypts payload.
- Benefits: minimizes KMS API calls (per-object key generated once), supports fine-grained access control, and simplifies key rotation (re-encrypt ciphertext data keys, not full payloads if data key rotation is managed).
- Secrets: use cloud Secrets Manager / Key Vault for secrets; do not store plaintext secrets in repo or CI artifacts.

Key rotation policy (recommended)
- CMK (customer-managed master keys):
  - Enable provider automatic rotation if the provider supports it (AWS automatic rotation = annual). If policy demands shorter rotation cadence, schedule manual rotation with documented steps.
  - Recommended default: enable automatic CMK rotation; require manual rotation for sensitive datasets every 90 days (if policy demands).
- Data keys:
  - Use ephemeral per-object data keys; rotate by generating new data keys on update/write. For large existing datasets, re-encrypt data keys (not necessarily full payload re-encryption if ciphertext data key envelope allows).
- Secret rotation:
  - Rotate credentials/secrets on compromise or quarterly; integrate with secret versioning and consumers to support seamless rotation.

Secrets handling
- Use managed secret stores (AWS Secrets Manager / GCP Secret Manager / Azure Key Vault).
- CI/CD: fetch secrets at runtime using short-lived credentials or federated workloads (OIDC) — avoid long-lived static credentials.
- Avoid secrets in logs; redact or use structured logging with suppression.

Cloud-specific notes & config examples
- AWS (recommended services)
  - KMS: AWS KMS Customer-managed CMKs (symmetric). Use GenerateDataKey / Decrypt APIs for envelope encryption.
  - S3: enable default SSE-KMS with CMK:
    aws s3api put-bucket-encryption --bucket my-bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"arn:aws:kms:us-east-1:123:key/abcd-..."} } ] }'
  - RDS/EBS: enable encryption using the CMK (create encrypted snapshots for migration).
  - Secrets: AWS Secrets Manager / Parameter Store (SecureString).
  - Audit: enable CloudTrail for KMS events; create CloudWatch alarms for kms:DisableKeyRotation, kms:ScheduleKeyDeletion, and unusual Decrypt volumes.
- GCP
  - KMS: Cloud KMS (KeyRings & CryptoKeys). Use CMEK for GCS, Cloud SQL where supported.
  - Storage: set bucket-level CMEK or use per-object envelope encryption.
  - Secrets: Secret Manager.
  - Audit: Cloud Audit Logs for KMS events; create alerts in Cloud Monitoring.
- Azure
  - Key Vault: Azure Key Vault (HSM-backed vaults via Managed HSM / SoftHSM).
  - Storage: Azure Storage Service Encryption with customer-managed keys (Key Vault).
  - DBs & Disks: enable Encryption at Rest with Key Vault integration.
  - Secrets: Key Vault secrets.
  - Audit: Diagnostic Settings to Event Hubs/Log Analytics for key events.

Migration / rollout plan (stepwise, low-risk)
1. Discovery & inventory (1–2 weeks)
   - Inventory buckets, DBs, disks, backups, caches, attachments, and third-party stores; record current encryption state.
2. Establish KMS & policies (0.5–1 week)
   - Create CMKs, define aliases, IAM roles/policies, and enable audit logging and key rotation settings.
3. Protect new resources (0–1 week)
   - Apply account-level guardrails and IaC changes to require encryption-by-default for new resources.
4. App changes & secrets integration (1–2 weeks)
   - Implement envelope encryption for new writes, integrate secret manager for runtime secrets, update apps to handle encrypted data key blobs.
5. Pilot migration (1 week)
   - Select low-risk dataset (small bucket); perform re-encryption via batch or copy; validate integrity and performance.
6. Bulk migration (variable, parallelizable)
   - S3/Blob: use batch operations (S3 Batch Operations, GCS batch jobs) to rewrite objects with SSE-KMS/CMEK. Throttle to avoid rate limits.
   - DBs: create encrypted replicas (if supported) or perform logical export & restore to encrypted instance. For large DBs, use replica + switchover.
   - Volumes: snapshot -> copy with encryption -> restore.
7. Validation & monitoring (ongoing)
   - Test decrypt operations, failure modes, latency, and audit logs.
8. Cutover & cleanup
   - Switch traffic to encrypted resources; retain backups/snapshots for rollback period.
9. Finalize rotation & compliance reporting
   - Implement scheduled rotations and document evidence.

Operational runbook summary (high-level)
- Key rotation (manual)
  1. Create new CMK (or enable auto-rotation where supported).
  2. Update key alias to point to new CMK as default where applicable.
  3. Re-encrypt data: for envelope pattern, rewrap encrypted data keys with new CMK or generate new data keys on next write; schedule bulk rewrap for static archives.
  4. Validate—test decryption across services.
  5. Decommission old CMK after retention window and ensure backups accessible.
- Key compromise incident playbook (summary)
  1. Immediately disable or revoke CMK use (KMS DisableKey).
  2. Identify scope: list resources/objects using the CMK, review CloudTrail/Audit logs for anomalous decrypts.
  3. Provision new CMKs and update applications to use them.
  4. Rotate secrets and credentials accessed with compromised key.
  5. Re-encrypt data keys or restore from pre-compromise encrypted backups as needed.
  6. Notify stakeholders, open incident, and follow compliance reporting; conduct root-cause analysis.
- Monitoring/alerting triggers
  - Key policy changes, enable/disable/delete actions, schedule key deletion events.
  - Spike in Decrypt failures or unusually high Decrypt requests.
  - Secrets access anomalies (unexpected sources).
  - CMK scheduled deletion / rotation not completed.
- On-call checklist
  - Steps to disable/deny policies, create emergency keys, update service IAM roles, and coordinate re-encryption.

Cost drivers (qualitative/back-of-envelope)
- Per-CMK monthly charge (customer-managed keys) and per-request KMS API costs — can be material if you call KMS for every request (envelope encryption minimizes this).
- Secrets manager charges per secret and per retrieval.
- Migration costs: compute to re-encrypt large object sets, snapshot storage, and snapshot copy charges.
- Operational engineering time for migration and ongoing management — larger for BYOK or self-hosted Vault.
- Recommended mitigation: use envelope encryption, cache decrypted data keys for short TTLs where safe, and minimize KMS operations for hot paths.

Operational burden assessment
- Provider-managed CMKs + managed Secrets: moderate initial setup and migration; low ongoing ops.
- BYOK / imported keys: high ops (HSM workflows, import, inventory), requires stricter key lifecycle processes.
- HashiCorp Vault (self-managed): high ops unless consumed as managed service.

Compatibility & API/versioning notes
- Use KMS APIs (GenerateDataKey/Decrypt) as stable primitives; implement a thin wrapper library to centralize key usage and handle provider differences. Version the wrapper library API to support key rotation and KMS provider swaps.

Follow-up todos (already added to session backlog)
- implement-kms
- enforce-encryption-new-resources
- envelope-encryption
- migrate-existing-s3-objects
- migrate-existing-volumes
- migrate-existing-databases
- update-ci-cd-secrets
- enable-kms-logging-monitoring
- create-key-compromise-runbook

Policy choice (single question)
Which key ownership model should be the default for this project?
A) Provider-managed CMKs (default): lowest operational burden; use CMEK/CMK where supported. (Recommended)
B) BYOK / Customer-controlled keys (imported HSM keys): stronger control for compliance, higher operational cost.
C) Hybrid: provider-managed for most data; BYOK for defined regulated datasets/services.

Please reply with A, B, or C. (If C, list which datasets/services require BYOK.)
