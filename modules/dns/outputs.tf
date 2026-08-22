output "name_servers" {
  description = "Give these to the domain registrar (GoDaddy)"
  value       = aws_route53_zone.main.name_servers
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "certificate_arn" {
  value = aws_acm_certificate_validation.main.certificate_arn
}

output "fqdn" {
  value = local.fqdn
}