variable "project" {
  type    = string
  default = "noise-to-signal"
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "ECR image tag for the Lambda function"
}

variable "shared_rds_secret_name" {
  type    = string
  default = "tck-labs/shared/rds"
}

variable "db_name" {
  type        = string
  description = "Postgres database name on the shared RDS host (e.g. noise_to_signal_dev)"
}

variable "google_oauth_secret_name" {
  type        = string
  default     = ""
  description = "Secrets Manager secret with GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET. Managed in AWS Console, not Terraform."
}

variable "memory_size" {
  type        = number
  default     = 1024
  description = "Lambda memory (MB)"
}

variable "timeout" {
  type        = number
  default     = 30
  description = "Lambda timeout (seconds)"
}

variable "public_hostname" {
  type        = string
  default     = ""
  description = "Function URL hostname without scheme. Set on a second apply for CSRF/SITE_DOMAIN."
}

variable "enable_lambda" {
  type        = bool
  default     = false
  description = "Set true after the first image has been pushed to ECR."
}
