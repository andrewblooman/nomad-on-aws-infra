output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_zone_id" {
  description = "The ID of the public hosted zone"
  value       = module.dns.public_zone_id
}

output "private_zone_id" {
  description = "The ID of the private hosted zone"
  value       = module.dns.private_zone_id
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.load_balancer.alb_dns_name
}

output "alb_dns_arn" {
  description = "The DNS name of the load balancer"
  value       = module.load_balancer.alb_arn
}

output "nomad_url" {
  description = "The URL to access the Nomad UI"
  value       = "https://nomad.${var.domain_name}"
}

output "api_url" {
  description = "The URL for the API Gateway"
  value       = "https://api.${var.domain_name}"
}
/*
output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider"
  value       = module.oidc_provider.provider_arn
}*/