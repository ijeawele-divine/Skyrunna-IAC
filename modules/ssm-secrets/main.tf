resource "aws_ssm_parameter" "secrets" {
  for_each = var.secrets

  name        = "/skyrunna/${var.env}/${each.key}"
  type        = "SecureString"
  value       = sensitive(each.value)
  description = "Skyrunna ${var.env} - ${each.key}"

  tags = {
    Environment = var.env
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [value]
  }
}