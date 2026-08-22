variable "env" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for this environment (e.g. 'uat' gives uat.example.com). Empty string uses root domain."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name to point at"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID"
  type        = string
}