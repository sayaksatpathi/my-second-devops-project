# ElastiCache Redis replication group. Scaffold.
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-redis-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "${var.name}-redis"
  description                = "OpsForge Redis cache"
  engine                     = "redis"
  node_type                  = var.node_type
  num_cache_clusters         = var.num_nodes
  automatic_failover_enabled = var.num_nodes > 1
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = var.security_group_ids
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  tags                       = var.tags
}
