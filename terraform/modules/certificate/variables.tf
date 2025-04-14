variable "domain_name" {
  description = "Domain name for the certificate"
  type        = string
}

variable "public_zone_id" {
  description = "ID of the public hosted zone"
  type        = string
}

variable "nomad_domain" {
  description = "Nomad domain name"
  type        = string
}

variable "api_domain" {
  description = "API Gateway domain name"
  type        = string
}