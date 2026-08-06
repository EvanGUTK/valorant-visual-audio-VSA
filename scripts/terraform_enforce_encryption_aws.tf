// Terraform snippet: Guardrails to enforce encryption-by-default for new AWS resources
// - AWS Config rule to ensure S3 buckets have default server-side encryption
// - Example IAM policy snippet to deny creation of unencrypted EBS volumes and unencrypted RDS instances

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

// Example: AWS Config managed rule to require S3 server-side encryption
resource "aws_config_config_rule" "s3_bucket_encrypted" {
  name = "s3-bucket-server-side-encryption-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
  // Optional input parameters can be provided if using custom rules
}

/*
Example IAM policy to deny creation of unencrypted resources (attach to IAM principals or use SCP in Organizations)
This is a JSON policy fragment shown as Terraform data for reference — convert to aws_iam_policy or AWS Organizations SCP as needed.
*/

data "aws_iam_policy_document" "deny_unencrypted_resources" {
  statement {
    sid = "DenyUnencryptedPutObjectOrVolumeOrRDS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "ec2:CreateVolume",
      "ec2:RunInstances",
      "rds:CreateDBInstance",
      "rds:ModifyDBInstance"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256", "aws:kms"]
    }

    // For EBS/RDS, use aws:RequestTag or specific request conditions to enforce kms key id presence.
    // Example for EBS: require kmsKeyId in CreateVolume request (providers may vary in request fields)
  }
}

output "config_rule_name" {
  value = aws_config_config_rule.s3_bucket_encrypted.name
}

/*
Notes and next steps:
- AWS Config rules are a good preventative/monitoring guardrail; to actively block unencrypted creation, use an SCP (Organizations) or IAM deny policy based on request conditions.
- For S3, enable default bucket encryption via aws_s3_bucket_server_side_encryption_configuration in your bucket modules.
- For EBS/RDS/EFS, ensure Terraform modules accept a kms_key_id argument and default to the CMK alias created earlier.
- For enforcement at account/org level, implement an Organizations SCP that denies actions when encryption headers/parameters are missing.
- Always test policies in a staging account to avoid accidental denials.
*/