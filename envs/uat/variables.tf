variable "jwt_secret" {
  description = "JWT signing secret (base64 encoded, min 32 bytes)"
  type        = string
  sensitive   = true
}

variable "encryption_key" {
  description = "Encryption key (base64 encoded)"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "RDS PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "super_admin_password_hash" {
  description = "BCrypt hash of super admin password"
  type        = string
  sensitive   = true
}

variable "resilience_service_api_key" {
  description = "Internal API key for resilience service"
  type        = string
  sensitive   = true
}

variable "notification_service_api_key" {
  description = "Internal API key for notification service"
  type        = string
  sensitive   = true
}

variable "report_service_api_key" {
  description = "Internal API key for report service"
  type        = string
  sensitive   = true
}

variable "sendgrid_api_key" {
  description = "SendGrid API key for email"
  type        = string
  sensitive   = true
}

variable "flutterwave_secret_key" {
  description = "Flutterwave secret key"
  type        = string
  sensitive   = true
}

variable "flutterwave_public_key" {
  description = "Flutterwave public key"
  type        = string
  sensitive   = true
}

variable "flutterwave_encryption_key" {
  description = "Flutterwave encryption key"
  type        = string
  sensitive   = true
}