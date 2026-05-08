resource "aws_cognito_user_pool" "main" {

  name                     = "my-user-pool"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }
  verification_message_template {
    email_message = "Your verification code is {####}"
    email_subject = "Your verification code"
  }
  mfa_configuration = "OFF"
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.cognito_domain // needs to be unique
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "client" {
  name                                 = "my-user-pool-client"
  user_pool_id                         = aws_cognito_user_pool.main.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]

  # Root path "/" -> CloudFront default_root_object (website_index_document -> index.html in S3)
  callback_urls = ["https://${var.app_host}/"]
  logout_urls   = ["https://${var.app_host}/"]

  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}