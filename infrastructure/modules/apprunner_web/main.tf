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

  # Dedicated Postgres database (catalog) on the shared RDS host.
  database_url = format(
    "postgresql://%s:%s@%s:%s/%s?sslmode=require",
    local.rds.username,
    urlencode(local.rds.password),
    local.rds.host,
    tostring(local.rds.port),
    var.db_name,
  )

  image_identifier = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"

  # Leading-dot host allows any *.awsapprunner.com until public_hostname is set.
  allowed_hosts = var.public_hostname != "" ? var.public_hostname : ".awsapprunner.com"
  csrf_origins  = var.public_hostname != "" ? "https://${var.public_hostname}" : ""
  site_domain   = var.public_hostname != "" ? var.public_hostname : "localhost"
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

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project}/${var.environment}/app"
  description             = "Signalfold App Runner runtime secrets"
  recovery_window_in_days = 0
  tags                    = local.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    SECRET_KEY           = random_password.django_secret.result
    DATABASE_URL         = local.database_url
    GOOGLE_CLIENT_ID     = var.google_client_id
    GOOGLE_CLIENT_SECRET = var.google_client_secret
  })
}

data "aws_iam_policy_document" "apprunner_ecr_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apprunner_ecr" {
  name               = "${local.name_prefix}-apprunner-ecr"
  assume_role_policy = data.aws_iam_policy_document.apprunner_ecr_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_ecr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

data "aws_iam_policy_document" "apprunner_instance_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apprunner_instance" {
  name               = "${local.name_prefix}-apprunner-instance"
  assume_role_policy = data.aws_iam_policy_document.apprunner_instance_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "apprunner_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.app.arn]
  }
}

resource "aws_iam_role_policy" "apprunner_secrets" {
  name   = "secrets"
  role   = aws_iam_role.apprunner_instance.id
  policy = data.aws_iam_policy_document.apprunner_secrets.json
}

resource "aws_apprunner_auto_scaling_configuration_version" "web" {
  count = var.enable_apprunner ? 1 : 0

  auto_scaling_configuration_name = local.name_prefix
  max_concurrency                 = var.max_concurrency
  min_size                        = var.min_size
  max_size                        = var.max_size
  tags                            = local.tags
}

resource "aws_apprunner_service" "web" {
  count = var.enable_apprunner ? 1 : 0

  service_name = local.name_prefix

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr.arn
    }

    auto_deployments_enabled = false

    image_repository {
      image_identifier      = local.image_identifier
      image_repository_type = "ECR"

      image_configuration {
        port = "8000"

        runtime_environment_variables = {
          DEBUG                = "false"
          DATABASE_SSL         = "true"
          ALLOWED_HOSTS        = local.allowed_hosts
          CSRF_TRUSTED_ORIGINS = local.csrf_origins
          SITE_DOMAIN          = local.site_domain
        }

        runtime_environment_secrets = {
          SECRET_KEY           = "${aws_secretsmanager_secret.app.arn}:SECRET_KEY::"
          DATABASE_URL         = "${aws_secretsmanager_secret.app.arn}:DATABASE_URL::"
          GOOGLE_CLIENT_ID     = "${aws_secretsmanager_secret.app.arn}:GOOGLE_CLIENT_ID::"
          GOOGLE_CLIENT_SECRET = "${aws_secretsmanager_secret.app.arn}:GOOGLE_CLIENT_SECRET::"
        }
      }
    }
  }

  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = aws_iam_role.apprunner_instance.arn
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.web[0].arn

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.apprunner_ecr,
    aws_iam_role_policy.apprunner_secrets,
    aws_secretsmanager_secret_version.app,
  ]
}
