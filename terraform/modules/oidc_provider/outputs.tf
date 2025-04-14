output "provider_arn" {
  description = "ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.nomad.arn
}

output "role_arn" {
  description = "ARN of the example IAM role"
  value       = aws_iam_role.nomad_workload.arn
}