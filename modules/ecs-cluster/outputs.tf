output "cluster_id" {
  value = aws_ecs_cluster.main.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "log_group_names" {
  value = {
    for k, v in aws_cloudwatch_log_group.services : k => v.name
  }
}

output "service_connect_namespace" {
  value = aws_service_discovery_http_namespace.main.arn
}