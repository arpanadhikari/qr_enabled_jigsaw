provider "aws" {
  region = "ap-southeast-2"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./lambda/"
  output_path = "lambda_function_payload.zip"
}


resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "jigsaw" {
  function_name = "jigsaw"

  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  role          = aws_iam_role.lambda_exec.arn
  # set timeout to 5 minutes
  timeout       = 300
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "lambda_exec_policy"
  role = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_exec_policy.json
}

#  policy data for lambda_exec_policy
data "aws_iam_policy_document" "lambda_exec_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
    ]

    resources = [
      aws_dynamodb_table.jigsaw.arn,
    ]
  }
}

// function alias
resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.jigsaw.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_alias" "live2" {
  name             = "live2"
  function_name    = aws_lambda_function.jigsaw.function_name
  function_version = "$LATEST"
}

resource "aws_lambda_function_url" "live" {
  function_name      = aws_lambda_function.jigsaw.function_name
  qualifier          = "live"
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "live2" {
  function_name      = aws_lambda_function.jigsaw.function_name
  qualifier          = "live2"
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

resource "aws_lambda_function_url" "main" {
  function_name      = aws_lambda_function.jigsaw.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}


output "live_url" {
  value = aws_lambda_function_url.live.function_url
}

output "live2_url" {
  value = aws_lambda_function_url.live2.function_url
}

output "main_url" {
  value = aws_lambda_function_url.main.function_url
}

// dynamodb table
resource "aws_dynamodb_table" "jigsaw" {
  name           = "jigsaw"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}