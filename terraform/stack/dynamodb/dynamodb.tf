# Single-table store for todos (PK = USER#sub, SK = TODO#…).
resource "aws_dynamodb_table" "app" {
  name         = "${var.app_name}-Todos"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }
}

# Events table (same key schema; use PK/SK patterns in application code).
resource "aws_dynamodb_table" "events" {
  name         = "${var.app_name}-Events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }
}

resource "aws_iam_role" "appsync_ddb" {
  name = "${var.app_name}-appsync-ddb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "appsync.amazonaws.com" }
    }]
  })
}

data "aws_iam_policy_document" "appsync_ddb" {
  statement {
    sid = "DynamoDBAppTables"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
    ]
    resources = [
      aws_dynamodb_table.app.arn,
      aws_dynamodb_table.events.arn,
    ]
  }
}

resource "aws_iam_role_policy" "appsync_ddb" {
  name   = "${var.app_name}-ddb-access"
  role   = aws_iam_role.appsync_ddb.id
  policy = data.aws_iam_policy_document.appsync_ddb.json
}
