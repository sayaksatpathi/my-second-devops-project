# Remote state (create the bucket/table via terraform/global first).
terraform {
  backend "s3" {
    bucket         = "opsforge-tfstate-sayak-637423616189-1790960539"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "opsforge-tf-locks"
    encrypt        = true
  }
}
