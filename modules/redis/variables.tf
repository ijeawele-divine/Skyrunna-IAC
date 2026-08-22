variable "env" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "Private data subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Redis security group ID"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
}