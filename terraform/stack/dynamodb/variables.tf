variable "app_name" {
  description = "Application name prefix; DynamoDB tables are \"{app_name}-Todos\" and \"{app_name}-Events\"."
  type        = string
  default     = "productivity-app"
}
