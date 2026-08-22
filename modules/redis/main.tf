resource "aws_elasticache_subnet_group" "main" {
  name       = "skyrunna-${var.env}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "skyrunna-${var.env}-redis-subnet-group"
    Environment = var.env
  }
}

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "skyrunna-${var.env}-redis"
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.security_group_id]

  tags = {
    Name        = "skyrunna-${var.env}-redis"
    Environment = var.env
  }
}