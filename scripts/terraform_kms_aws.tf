// Terraform snippet: AWS KMS CMK module (example)
// Place this in your infra Terraform and adapt to your module structure.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "alias_name" {
  type    = string
  default = "alias/project-cmk"
}

variable "description" {
  type    = string
  default = "Customer-managed CMK for project resources"
}

variable "enable_key_rotation" {
  type    = bool
  default = true
}

variable "deletion_window" {
  type    = number
  default = 30
}

provider "aws" {
  region = var.region
}

resource "aws_kms_key" "cmk" {
  description             = var.description
  enable_key_rotation    = var.enable_key_rotation
  deletion_window_in_days = var.deletion_window

  tags = {
    Name = "project-cmk"
  }
}

resource "aws_kms_alias" "cmk_alias" {
  name          = var.alias_name
  target_key_id = aws_kms_key.cmk.key_id
}

output "key_arn" {
  value = aws_kms_key.cmk.arn
}

output "key_id" {
  value = aws_kms_key.cmk.key_id
}

output "alias_name" {
  value = aws_kms_alias.cmk_alias.name
}

/*
Notes:
- This example creates a symmetric CMK and an alias. In production, attach a restrictive key policy that limits who can use and manage the key.
- Enable CloudTrail (or verify existing trails) to capture kms:* events. Example CloudTrail configuration is not enforced here; audit logging should be configured at account level.
- For CMEK integration with services (S3, RDS, EBS, etc.), provide the CMK ARN or alias where the service supports CMEK.
- For BYOK/HSM workflows, consult your provider docs to import keys or use Managed HSM.
*/