variable "env" {
  description = "Environment name"
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID"
  type        = string
}

variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "image_url" {
  description = "Full ECR image URL including tag"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "cpu" {
  description = "Fargate CPU units (256, 512, 1024, 2048)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of tasks to run"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Subnet IDs to run tasks in"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for tasks"
  type        = list(string)
}

variable "task_execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name"
  type        = string
}

variable "environment_variables" {
  description = "Non-sensitive environment variables"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of env var name to SSM parameter ARN"
  type        = map(string)
  default     = {}
}

variable "target_group_arn" {
  description = "ALB target group ARN (optional, only for gateway and frontend)"
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "Health check path for ALB (only used when target_group_arn is set)"
  type        = string
  default     = "/actuator/health"
}

variable "service_connect_enabled" {
  description = "Whether to enable Service Connect for internal DNS"
  type        = bool
  default     = true
}

variable "service_connect_namespace" {
  description = "Service Connect namespace"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "health_check_command" {
  description = "Custom health check command. Set to empty list to disable."
  type        = list(string)
  default     = []
}