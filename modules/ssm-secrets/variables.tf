variable "env" {
  description = "Environment name"
  type        = string
}

variable "secrets" {
  description = "Map of secret name to secret value"
  type        = map(string)
}