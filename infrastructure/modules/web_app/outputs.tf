output "function_name" {
  value = aws_lambda_function.web.function_name
}

output "function_arn" {
  value = aws_lambda_function.web.arn
}

output "function_url" {
  description = "Raw Lambda Function URL (origin only; prefer service_url)"
  value       = aws_lambda_function_url.web.function_url
}

output "service_url" {
  description = "Public HTTPS CloudFront URL (stable; use for Google OAuth)"
  value       = "https://${aws_cloudfront_distribution.web.domain_name}/"
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.web.domain_name
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
