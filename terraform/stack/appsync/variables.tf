# -------------------------------------------------------
# Variables
# -------------------------------------------------------
variable "user_pool_id" {
  description = "Cognito User Pool ID for AppSync authentication"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "api_name" {
  description = "Display name for the AppSync GraphQL API and prefix for related resources (-logs-role, datasource name, etc.)."
  type        = string
  default     = "my-appsync-api"
}

variable "dynamodb_todos_table_name" {
  description = "Todos DynamoDB table name (from dynamodb module)"
  type        = string
}

variable "dynamodb_events_table_name" {
  description = "Events DynamoDB table name (from dynamodb module)"
  type        = string
}

variable "appsync_ddb_service_role_arn" {
  description = "IAM service role ARN AppSync uses for DynamoDB"
  type        = string
}
