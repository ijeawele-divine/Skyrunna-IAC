variable "env" {
  description = "Environment name"
  type        = string
}

variable "alarm_email" {
  description = "Email addresses to receive alarm notifications"
  type        = list(string)
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "gateway_target_group_arn_suffix" {
  description = "Gateway target group ARN suffix"
  type        = string
}

variable "frontend_target_group_arn_suffix" {
  description = "Frontend target group ARN suffix"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_names" {
  description = "List of ECS service names to monitor"
  type        = list(string)
}