# Disaster-recovery environment: mirrors dev/prod in a SECOND region.
# Stand this up (or keep it warm) and restore RDS from a cross-region snapshot
# during a DR drill. See docs/disaster-recovery.md.
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
  cidr_block         = "10.1.0.0/16" # distinct from primary (10.0.0.0/16)
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  single_nat_gateway = false # DR mirrors prod HA
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
  multi_az   = true # DR: highly available
  tags       = local.tags
}

module "redis" {
  source     = "../../modules/redis"
  name       = local.name
  subnet_ids = module.vpc.private_subnet_ids
  num_nodes  = 2
  tags       = local.tags
}
