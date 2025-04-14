variable "nomad_url" {
  description = "URL of the Nomad server"
  type        = string
}

variable "api_url" {
  description = "URL of the API Gateway"
  type        = string
}

variable "provider_name" {
  description = "Name of the OIDC provider"
  type        = string
}