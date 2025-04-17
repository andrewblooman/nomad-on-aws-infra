# Variables needed for the Windows bastion
variable "my_ip_address" {
  description = "Your IP address for RDP access to the Windows bastion"
  type        = string
}

variable "bastion_instance_type" {
  description = "Instance type for the Windows bastion"
  type        = string
  default     = "t3.large"
}

variable "create_dns_record" {
  description = "Whether to create a DNS record for the Windows bastion"
  type        = bool
  default     = false
}

variable "public_zone_id" {
  description = "Route53 public hosted zone ID for the domain"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID where the Windows bastion will be deployed"
  type        = string
  default     = ""
  
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
  default     = ""
}
variable "key_name" {
  description = "Key pair name for SSH access to the Windows bastion"
  type        = string
  default     = ""
  
}

variable "public_subnets" {
  description = "List of public subnets for the Windows bastion"
  type        = list(string)
  default     = []
  
}
variable "domain_name" {
  type = string
}