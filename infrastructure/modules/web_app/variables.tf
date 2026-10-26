variable "project" {
  type = string
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
  description = "ECR image tag (must already exist in the base-stack repository)"
}

variable "ecr_repository_url" {
  type        = string
  description = "From the base stack (ECR)"
}

variable "shared_rds_secret_name" {
  type    = string
  default = "tck-labs/shared/rds"
}

variable "db_name" {
  type = string
}

variable "google_oauth_secret_name" {
  type        = string
  default     = ""
  description = "Secrets Manager secret with GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET"
}

variable "memory_size" {
  type    = number
  default = 1024
}

variable "timeout" {
  type    = number
  default = 30
}
