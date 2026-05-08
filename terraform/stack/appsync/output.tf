# -------------------------------------------------------
# Outputs
# -------------------------------------------------------
output "appsync_url" {
  description = "AppSync GraphQL endpoint URL"
  value       = aws_appsync_graphql_api.main.uris["GRAPHQL"]
}

output "appsync_api_id" {
  description = "AppSync API ID"
  value       = aws_appsync_graphql_api.main.id
}

output "dynamodb_todos_table_name" {
  description = "Todos DynamoDB table wired to AppSync"
  value       = var.dynamodb_todos_table_name
}

output "dynamodb_events_table_name" {
  description = "Events DynamoDB table wired to AppSync"
  value       = var.dynamodb_events_table_name
}
