output "alb_dns_name" {
  description = "Access the app at this URL"
  value       = module.alb.alb_dns_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "redis_endpoint" {
  value = module.redis.endpoint
}

output "role_arn" {
  value = module.github_oidc.role_arn
}

output "dashboard_url" {
  value = module.monitoring.dashboard_url
}

output "cdn_domain_name" {
  description = "CloudFront domain for static/marketing assets (e.g. demo video)"
  value       = module.cdn_assets.distribution_domain_name
}