variable "project" {
  type    = string
  default = "signalfold"
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
  description = "ECR image tag for the App Runner service"
}

variable "shared_rds_secret_name" {
  type    = string
  default = "tck-labs/shared/rds"
}

variable "db_name" {
  type        = string
  description = "Postgres database name on the shared RDS host (e.g. signalfold_dev)"
}

variable "google_oauth_secret_name" {
  type        = string
  default     = ""
  description = "Secrets Manager secret with GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET. Managed in AWS Console, not Terraform."
}

variable "cpu" {
  type    = string
  default = "256"
}

variable "memory" {
  type    = string
  default = "512"
}

variable "max_concurrency" {
  type    = number
  default = 100
}

variable "min_size" {
  type        = number
  default     = 1
  description = "App Runner MinSize is at least 1 (memory billed when idle; CPU only when active)"
}

variable "max_size" {
  type    = number
  default = 3
}

variable "public_hostname" {
  type        = string
  default     = ""
  description = "App Runner hostname without scheme (from service_url). Set on a second apply for CSRF/SITE_DOMAIN."
}

variable "enable_apprunner" {
  type        = bool
  default     = false
  description = "Set true after the first image has been pushed to ECR."
}
