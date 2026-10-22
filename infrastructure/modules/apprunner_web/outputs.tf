output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.app.name
}

output "service_arn" {
  value = try(aws_apprunner_service.web[0].arn, null)
}

output "service_url" {
  value = try(aws_apprunner_service.web[0].service_url, null)
}

output "service_id" {
  value = try(aws_apprunner_service.web[0].service_id, null)
}

output "app_secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "app_secret_name" {
  value = aws_secretsmanager_secret.app.name
}

output "db_name" {
  value = var.db_name
}

output "image_identifier" {
  value = local.image_identifier
}
