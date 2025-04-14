# variables.tf

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "nomad-vpc"
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 3
}

variable "domain_name" {
  description = "Domain name for the cluster"
  type        = string
  default     = "nomadsilo.com"
}

variable "private_zone_name" {
  description = "Private DNS zone name"
  type        = string
  default     = "internal.nomadsilo.com"
}

variable "cluster_name" {
  description = "Name of the Nomad cluster"
  type        = string
  default     = "nomad-cluster"
}

variable "server_instance_type" {
  description = "Instance type for Nomad servers"
  type        = string
  default     = "t3.medium"
}

variable "client_instance_type" {
  description = "Instance type for Nomad clients"
  type        = string
  default     = "t3.large"
}

variable "server_count" {
  description = "Number of Nomad server nodes"
  type        = number
  default     = 3
}

variable "client_min_size" {
  description = "Minimum number of Nomad client nodes"
  type        = number
  default     = 3
}

variable "client_max_size" {
  description = "Maximum number of Nomad client nodes"
  type        = number
  default     = 10
}

variable "client_desired_size" {
  description = "Desired number of Nomad client nodes"
  type        = number
  default     = 3
}

variable "waf_enabled" {
  description = "Enable AWS WAF for API Gateway"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = "Nomad-key" # Replace with your key pair name

}