output "appsync_graphql_url" {
  description = "AppSync GraphQL HTTPS endpoint"
  value       = module.appsync.appsync_url
}

# output "appsync_api_id" {
#   description = "AppSync API ID"
#   value       = module.appsync.appsync_api_id
# }

output "cloudfront_distribution_url" {
  value = module.s3.cloudfront_domain_name
}
output "hosted_ui_login_url" {
  value = "https://${module.cognito.domain}.auth.${var.aws_region}.amazoncognito.com/login?response_type=code&client_id=${module.cognito.client_id}&redirect_uri=https://${module.cognito.app_host}/"
}

output "user_pool_id" {
  value = module.cognito.user_pool_id
}

output "client_id" {
  value = module.cognito.client_id
}



