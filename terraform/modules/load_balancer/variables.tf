variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "nomad_domain" {
  description = "Domain name for Nomad UI"
  type        = string
}

variable "public_zone_id" {
  description = "ID of the public hosted zone"
  type        = string
}