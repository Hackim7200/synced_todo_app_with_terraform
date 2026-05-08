terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "./stack/s3"
}

module "cognito" {
  source = "./stack/cognito"

  # After login, redirect to CloudFront URL (/) which serves website/index.html
  app_host = module.s3.cloudfront_domain_name
}

module "dynamodb" {
  source = "./stack/dynamodb"
}

module "appsync" {
  source = "./stack/appsync"

  aws_region                   = var.aws_region
  user_pool_id                 = module.cognito.user_pool_id
  dynamodb_todos_table_name    = module.dynamodb.todos_table_name
  dynamodb_events_table_name   = module.dynamodb.events_table_name
  appsync_ddb_service_role_arn = module.dynamodb.appsync_ddb_service_role_arn

  depends_on = [module.dynamodb]
}
