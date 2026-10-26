output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Delegate the domain at your registrar to these Route 53 name servers"
  value       = aws_route53_zone.main.name_servers
}

output "domain_name" {
  value = var.domain_name
}

output "acm_certificate_arn" {
  description = "us-east-1 ACM cert (wildcard) for CloudFront"
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}
