terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "shared_rds" {
  name = var.shared_rds_secret_name
}

data "aws_secretsmanager_secret_version" "shared_rds" {
  secret_id = data.aws_secretsmanager_secret.shared_rds.id
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
  }

  rds = jsondecode(data.aws_secretsmanager_secret_version.shared_rds.secret_string)

  database_url = format(
    "postgresql://%s:%s@%s:%s/%s?sslmode=require",
    local.rds.username,
    urlencode(local.rds.password),
    local.rds.host,
    tostring(local.rds.port),
    var.db_name,
  )

  image_identifier = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"

  # Leading-dot host allows any *.lambda-url.<region>.on.aws until public_hostname is set.
  allowed_hosts = var.public_hostname != "" ? var.public_hostname : ".lambda-url.${var.aws_region}.on.aws"
  csrf_origins  = var.public_hostname != "" ? "https://${var.public_hostname}" : ""
  site_domain   = var.public_hostname != "" ? var.public_hostname : "localhost"

  google_oauth_secret_name = var.google_oauth_secret_name != "" ? var.google_oauth_secret_name : "${var.project}/${var.environment}/google-oauth"

  app_secret   = jsondecode(aws_secretsmanager_secret_version.app.secret_string)
  google_oauth = jsondecode(data.aws_secretsmanager_secret_version.google_oauth.secret_string)
}

resource "random_password" "django_secret" {
  length  = 50
  special = false
}

resource "aws_ecr_repository" "app" {
  name                 = local.name_prefix
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

# Allow Lambda to pull images from this repository.
resource "aws_ecr_repository_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "LambdaECRImageRetrievalPolicy"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
      ]
      Condition = {
        StringLike = {
          "aws:sourceArn" = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}"
        }
      }
    }]
  })
}

data "aws_secretsmanager_secret" "google_oauth" {
  name = local.google_oauth_secret_name
}

data "aws_secretsmanager_secret_version" "google_oauth" {
  secret_id = data.aws_secretsmanager_secret.google_oauth.id
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project}/${var.environment}/app"
  description             = "noise-to-signal Lambda runtime secrets (SECRET_KEY, DATABASE_URL)"
  recovery_window_in_days = 0
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    SECRET_KEY   = random_password.django_secret.result
    DATABASE_URL = local.database_url
  })
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      aws_secretsmanager_secret.app.arn,
      data.aws_secretsmanager_secret.google_oauth.arn,
    ]
  }
}

resource "aws_iam_role_policy" "lambda_secrets" {
  name   = "secrets"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_secrets.json
}

resource "aws_lambda_function" "web" {
  count = var.enable_lambda ? 1 : 0

  function_name = local.name_prefix
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  image_uri     = local.image_identifier
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = ["x86_64"]

  image_config {
    command = ["config.lambda_handler.handler"]
  }

  environment {
    variables = {
      DEBUG                = "false"
      DATABASE_SSL         = "true"
      ALLOWED_HOSTS        = local.allowed_hosts
      CSRF_TRUSTED_ORIGINS = local.csrf_origins
      SITE_DOMAIN          = local.site_domain
      SECRET_KEY           = local.app_secret.SECRET_KEY
      DATABASE_URL         = local.app_secret.DATABASE_URL
      GOOGLE_CLIENT_ID     = local.google_oauth.GOOGLE_CLIENT_ID
      GOOGLE_CLIENT_SECRET = local.google_oauth.GOOGLE_CLIENT_SECRET
    }
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_secrets,
    aws_ecr_repository_policy.app,
    aws_secretsmanager_secret_version.app,
  ]
}

resource "aws_lambda_function_url" "web" {
  count = var.enable_lambda ? 1 : 0

  function_name      = aws_lambda_function.web[0].function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "function_url" {
  count = var.enable_lambda ? 1 : 0

  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.web[0].function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}
