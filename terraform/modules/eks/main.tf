# EKS via the community module. Scaffold — pin versions & review before apply.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
  default = {
    min_size       = var.node_min
    max_size       = var.node_max
    desired_size   = var.node_desired
    instance_types = var.instance_types
    ami_type       = "AL2023_x86_64_STANDARD"
  }
}

  tags = var.tags
}
