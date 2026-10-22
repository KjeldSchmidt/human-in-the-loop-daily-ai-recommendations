variable "image_tag" {
  type    = string
  default = "latest"
}

variable "public_hostname" {
  type        = string
  default     = ""
  description = "Set after first apply to the hostname from service_url (no https://)"
}

variable "enable_apprunner" {
  type        = bool
  default     = false
  description = "false on first apply (ECR + secrets only); true after push_image"
}
