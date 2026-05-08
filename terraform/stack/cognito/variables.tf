variable "app_host" {
  description = "frontend hostname"
  type        = string
  default     = "localhost"
}

variable "app_port" {
  description = "The port of the application"
  type        = number
  default     = 3000
}

variable "cognito_domain" {
  description = "Unique domain name for Cognito"
  type        = string
  default     = "my-user-pool-domain"
}