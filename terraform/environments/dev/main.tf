# Dev environment: composes the reusable modules. Scaffold — review before apply.
provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "opsforge-${var.environment}"
  tags = {
    Project     = "opsforge"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source             = "../../modules/vpc"
  name               = local.name
  cidr_block         = "10.0.0.0/16"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  single_nat_gateway = true # dev: cheaper; prod: false for HA
  tags               = local.tags
}

module "ecr" {
  source = "../../modules/ecr"
  name   = local.name
  tags   = local.tags
}

module "eks" {
  source             = "../../modules/eks"
  cluster_name       = local.name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  tags               = local.tags
}

module "rds" {
  source     = "../../modules/rds"
  name       = local.name
  subnet_ids = module.vpc.private_subnet_ids
  password   = var.db_password
  multi_az   = false # dev
  tags       = local.tags
}

module "redis" {
  source     = "../../modules/redis"
  name       = local.name
  subnet_ids = module.vpc.private_subnet_ids
  num_nodes  = 1 # dev
  tags       = local.tags
}

module "iam" {
  source = "../../modules/iam"
  name   = local.name
  tags   = local.tags
}
