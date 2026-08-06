// Terraform snippet: Enable CloudTrail logging for KMS events, deliver to S3 and CloudWatch Logs, and create EventBridge rules + SNS alerts for sensitive KMS operations.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "alert_email" {
  type    = string
  default = "oncall@example.com"
}

variable "trail_name" {
  type    = string
  default = "project-cloudtrail"
}

variable "log_bucket_name" {
  type    = string
  default = "project-cloudtrail-logs-${var.region}"
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = var.log_bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        # Optionally specify KMS key id: kms_master_key_id = aws_kms_key.cmk.arn
      }
    }
  }

  lifecycle_rule {
    id      = "expire-logs"
    enabled = true
    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

// IAM role for CloudTrail to publish to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "cloudtrail-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/${var.trail_name}"
  retention_in_days = 365
}

resource "aws_cloudtrail" "project_trail" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]

  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn
  cloud_watch_logs_group_arn = aws_cloudwatch_log_group.cloudtrail_logs.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
    data_resource {
      type = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
}

// SNS topic for alerts
resource "aws_sns_topic" "kms_alerts" {
  name = "project-kms-alerts"
}

// EventBridge rule to catch KMS management events of interest
resource "aws_cloudwatch_event_rule" "kms_sensitive_ops" {
  name        = "kms-sensitive-operations"
  description = "Match KMS sensitive API calls like DisableKeyRotation, ScheduleKeyDeletion, and Decrypt spiking"

  event_pattern = jsonencode({
    source = ["aws.kms"],
    detail = {
      eventName = ["DisableKeyRotation", "ScheduleKeyDeletion", "CreateKey", "ImportKeyMaterial", "ReEncrypt*", "GenerateDataKey", "Decrypt"]
    }
  })
}

resource "aws_cloudwatch_event_target" "kms_to_sns" {
  rule      = aws_cloudwatch_event_rule.kms_sensitive_ops.name
  arn       = aws_sns_topic.kms_alerts.arn
  target_id = "send-to-sns"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.kms_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email // set via variables or replace
}

output "cloudtrail_bucket" {
  value = aws_s3_bucket.cloudtrail_bucket.id
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.cloudtrail_logs.name
}

/*
Notes:
- Set var.alert_email to the incident on-call or an escalation distribution.
- For Decrypt-rate anomalies consider using CloudWatch metric math or create a metric filter to count Decrypt events from CloudTrail logs and alarm when rate exceeds threshold.
- This snippet is an example; adapt for multi-region trails, S3 bucket policies, and encryption keys (CMEK) per org policies.
- Test in staging; EventBridge rules may need refinement for event detail shapes.
*/