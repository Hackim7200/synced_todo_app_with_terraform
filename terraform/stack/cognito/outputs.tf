output "domain" {
  value = aws_cognito_user_pool_domain.main.domain
}

output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "app_host" {
  value = var.app_host
}

output "app_port" {
  value = var.app_port
}
