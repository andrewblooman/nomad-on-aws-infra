output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_apigatewayv2_api.nomad.id
}

output "api_endpoint" {
  description = "Endpoint URL of the API Gateway"
  value       = aws_apigatewayv2_api.nomad.api_endpoint
}

output "api_gateway_domain" {
  description = "Custom domain for API Gateway"
  value       = var.api_domain
}