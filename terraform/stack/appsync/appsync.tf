
# -------------------------------------------------------
# IAM Role for AppSync logging
# -------------------------------------------------------
resource "aws_iam_role" "appsync_logs" {
  name = "${var.api_name}-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "appsync.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "appsync_logs" {
  role       = aws_iam_role.appsync_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppSyncPushToCloudWatchLogs"
}

# -------------------------------------------------------
# AppSync GraphQL API
# -------------------------------------------------------
resource "aws_appsync_graphql_api" "main" {
  name                = var.api_name
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  schema              = file("${path.module}/graphql/schema.graphql")

  user_pool_config {
    user_pool_id   = var.user_pool_id
    aws_region     = var.aws_region
    default_action = "ALLOW"
  }

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ERROR"
  }

  xray_enabled = false
}

# -------------------------------------------------------
# Data sources — DynamoDB (Todos + Events)
# -------------------------------------------------------
resource "aws_appsync_datasource" "todos" {
  api_id           = aws_appsync_graphql_api.main.id
  # AppSync requires [_A-Za-z][_0-9A-Za-z]* — no hyphens in data source names.
  name             = "TodosDataSource"
  type             = "AMAZON_DYNAMODB"
  service_role_arn = var.appsync_ddb_service_role_arn

  dynamodb_config {
    table_name = var.dynamodb_todos_table_name
    region     = var.aws_region
  }
}

resource "aws_appsync_datasource" "events" {
  api_id           = aws_appsync_graphql_api.main.id
  name             = "EventsDataSource"
  type             = "AMAZON_DYNAMODB"
  service_role_arn = var.appsync_ddb_service_role_arn

  dynamodb_config {
    table_name = var.dynamodb_events_table_name
    region     = var.aws_region
  }
}

# -------------------------------------------------------
# Resolvers — APPSYNC_JS (see graphql/resolver/)
# -------------------------------------------------------
locals {
  appsync_resolvers = {
    Query_getTodo = {
      type  = "Query"
      field = "getTodo"
      path  = "todo/getTodo.js"
    }
    Query_listTodos = {
      type  = "Query"
      field = "listTodos"
      path  = "todo/listTodos.js"
    }
    Query_listTodosUpdatedAfter = {
      type  = "Query"
      field = "listTodosUpdatedAfter"
      path  = "todo/listTodosUpdatedAfter.js"
    }
    Mutation_createTodo = {
      type  = "Mutation"
      field = "createTodo"
      path  = "todo/createTodo.js"
    }
    Mutation_updateTodo = {
      type  = "Mutation"
      field = "updateTodo"
      path  = "todo/updateTodo.js"
    }
    Mutation_deleteTodo = {
      type  = "Mutation"
      field = "deleteTodo"
      path  = "todo/deleteTodo.js"
    }
  }
}

resource "aws_appsync_resolver" "field" {
  for_each = local.appsync_resolvers

  api_id      = aws_appsync_graphql_api.main.id
  type        = each.value.type
  field       = each.value.field
  kind        = "UNIT"
  data_source = aws_appsync_datasource.todos.name

  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }

  code = file("${path.module}/graphql/resolver/${each.value.path}")

  depends_on = [aws_appsync_graphql_api.main]
}

