# DR state lives under a separate key (same bucket, or a DR-region bucket).
terraform {
  backend "s3" {
    bucket         = "opsforge-tfstate"
    key            = "dr/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "opsforge-tf-locks"
    encrypt        = true
  }
}
