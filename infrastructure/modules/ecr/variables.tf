variable "project" {
  type        = string
  description = "Repository name / project slug (shared across environments)"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}
