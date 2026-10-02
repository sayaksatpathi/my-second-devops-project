# Bootstraps the Terraform remote-state backend (S3 bucket + DynamoDB lock).
# Apply this ONCE before the environment stacks. Scaffold.
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "state_bucket" {
  type    = string
  default = "opsforge-tfstate"
}
variable "lock_table" {
  type    = string
  default = "opsforge-tf-locks"
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket
}
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
