variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Nomad cluster"
  type        = string
}