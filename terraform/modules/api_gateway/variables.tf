variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "nomad_alb_dns" {
  description = "DNS name of the Nomad ALB"
  type        = string
}

variable "nomad_domain" {
  description = "Domain name for Nomad UI"
  type        = string
}

variable "api_domain" {
  description = "Domain name for API Gateway"
  type        = string
}

variable "public_zone_id" {
  description = "ID of the public hosted zone"
  type        = string
}

variable "waf_enabled" {
  description = "Enable AWS WAF for API Gateway"
  type        = bool
  default     = true
}