variable "domain_name" {
  description = "Domain name for the cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_zone_name" {
  description = "Private DNS zone name"
  type        = string
}
