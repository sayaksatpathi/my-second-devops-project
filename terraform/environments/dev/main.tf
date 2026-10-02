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

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "Allow PostgreSQL from EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-rds"
  })
}
module "rds" {
  source             = "../../modules/rds"
  name               = local.name
  subnet_ids         = module.vpc.private_subnet_ids
  password           = var.db_password
  security_group_ids = [aws_security_group.rds.id]
  multi_az           = false
  tags               = local.tags
}

resource "aws_security_group" "redis" {
  name        = "${local.name}-redis"
  description = "Allow Redis traffic from EKS worker nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-redis"
  })
}

module "redis" {
  source             = "../../modules/redis"
  name               = local.name
  subnet_ids         = module.vpc.private_subnet_ids
  num_nodes          = 1 # dev
  security_group_ids = [aws_security_group.redis.id]
  tags               = local.tags
}

module "iam" {
  source = "../../modules/iam"
  name   = local.name
  tags   = local.tags
}

# Billing guardrail: a monthly budget with alerts (see modules/budget).
module "budget" {
  source             = "../../modules/budget"
  name               = local.name
  limit_amount       = var.budget_limit
  notification_email = var.budget_email
}
