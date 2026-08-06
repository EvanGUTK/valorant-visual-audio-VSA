KMS Logging & Monitoring (AWS) — scripts/terraform_kms_logging_aws.tf

Purpose
- Ensure KMS API activity is captured and routed to durable storage and observability systems, and alert on sensitive key management operations or anomalous Decrypt volumes.

What the Terraform snippet does
- Creates an S3 bucket for CloudTrail logs (with SSE-KMS enabled).
- Creates a CloudTrail that records management events and forwards logs to CloudWatch Logs.
- Creates an EventBridge (CloudWatch Events) rule that matches sensitive KMS operations (DisableKeyRotation, ScheduleKeyDeletion, ImportKeyMaterial, CreateKey, GenerateDataKey, Decrypt, etc.) and sends alerts to an SNS topic.
- Creates an SNS topic subscription placeholder (email) — set var.alert_email before deployment.

Deployment guidance
1. Create or reuse a secure, central CloudTrail S3 bucket. Ensure cross-account access and encryption are correctly configured.
2. Deploy the CloudTrail in the management/monitoring account or the account owning CMKs (depending on org topology). Consider multi-region trails if keys are used across regions.
3. Configure alerting to an on-call channel (PagerDuty email, Slack via Lambda subscription, or other integrations) rather than a single email address.
4. To detect Decrypt-volume anomalies, add a CloudWatch metric filter reading CloudTrail logs for Decrypt events and alarm on high counts or unexpected source principals.

Alert tuning & runbook
- Tune event filters to reduce noise; exclude expected automated services (e.g., Lambda with known behavior) via event pattern exclusions or additional conditions.
- Create runbook steps for each alert type (policy change, key deletion scheduling, import of key material, large volume of Decrypt calls) describing investigation steps, key rotation actions, and stakeholder notification.

Security notes
- The CloudTrail S3 bucket must be locked down: block public access, restrict ACLs, require encryption, and enable MFA-delete where supported and appropriate.
- CloudWatch Logs & SNS attachments must have restricted IAM so only monitoring systems and on-call can view/trigger.

Next steps
- Add a CloudWatch Logs metric filter & alarm for frequent Decrypt events, and an automated suppression whitelist for known service principals.
- Integrate SNS → Lambda → Slack/PagerDuty for richer alerts.
- Add automated evidence collection (playbook) to the incident response for KMS key compromise events.
