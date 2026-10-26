output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.app.name
}

output "function_name" {
  value = try(aws_lambda_function.web[0].function_name, null)
}

output "function_arn" {
  value = try(aws_lambda_function.web[0].arn, null)
}

output "service_url" {
  description = "Public HTTPS Function URL (trailing slash)"
  value       = try(aws_lambda_function_url.web[0].function_url, null)
}

output "app_secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}

output "app_secret_name" {
  value = aws_secretsmanager_secret.app.name
}

output "google_oauth_secret_name" {
  value = data.aws_secretsmanager_secret.google_oauth.name
}

output "db_name" {
  value = var.db_name
}

output "image_identifier" {
  value = local.image_identifier
}
