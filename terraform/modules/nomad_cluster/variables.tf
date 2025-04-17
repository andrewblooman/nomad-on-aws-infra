variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "nomad_server_sg_id" {
  description = "ID of the Nomad server security group"
  type        = string
}

variable "nomad_client_sg_id" {
  description = "ID of the Nomad client security group"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Nomad cluster"
  type        = string
}

variable "server_instance_type" {
  description = "Instance type for Nomad servers"
  type        = string
}

variable "client_instance_type" {
  description = "Instance type for Nomad clients"
  type        = string
}

variable "server_count" {
  description = "Number of Nomad server nodes"
  type        = number
}

variable "client_desired_size" {
  description = "Desired number of Nomad client nodes"
  type        = number
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the cluster"
  type        = string
}

variable "api_url" {
  description = "URL of the API Gateway"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "private_zone_id" {
  description = "ID of the private hosted zone"
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 key pair to use"
  type        = string
  default     = null # Make it optional
}