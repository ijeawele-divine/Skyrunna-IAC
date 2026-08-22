output "parameter_arns" {
  description = "Map of secret name to SSM parameter ARN"
  value = {
    for k, v in aws_ssm_parameter.secrets : k => v.arn
  }
  sensitive = true
}

output "parameter_names" {
  description = "Map of secret name to SSM parameter name"
  value = {
    for k, v in aws_ssm_parameter.secrets : k => v.name
  }
}