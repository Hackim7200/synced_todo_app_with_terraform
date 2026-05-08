output "todos_table_name" {
  description = "Todos DynamoDB table name"
  value       = aws_dynamodb_table.app.name
}

output "todos_table_arn" {
  description = "Todos DynamoDB table ARN"
  value       = aws_dynamodb_table.app.arn
}

output "events_table_name" {
  description = "Events DynamoDB table name"
  value       = aws_dynamodb_table.events.name
}

output "events_table_arn" {
  description = "Events DynamoDB table ARN"
  value       = aws_dynamodb_table.events.arn
}

output "appsync_ddb_service_role_arn" {
  description = "IAM role AppSync assumes for DynamoDB access"
  value       = aws_iam_role.appsync_ddb.arn
}
