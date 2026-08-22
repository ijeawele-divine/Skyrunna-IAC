output "alb_dns_name" {
  description = "ALB DNS name - use this to access the app before Route53 is configured"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "gateway_target_group_arn" {
  value = aws_lb_target_group.gateway.arn
}

output "frontend_target_group_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}

output "gateway_target_group_arn_suffix" {
  value = aws_lb_target_group.gateway.arn_suffix
}

output "frontend_target_group_arn_suffix" {
  value = aws_lb_target_group.frontend.arn_suffix
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}