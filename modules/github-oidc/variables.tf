variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repos" {
  description = "List of repository names allowed to assume this role"
  type        = list(string)
}

variable "env" {
  description = "Environment name"
  type        = string
}
