output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "nomad_server_sg_id" {
  description = "ID of the Nomad server security group"
  value       = aws_security_group.nomad_server_sg.id
}

output "nomad_client_sg_id" {
  description = "ID of the Nomad client security group"
  value       = aws_security_group.nomad_client_sg.id
}

# Add to your security module outputs (modules/security/outputs.tf)
output "endpoint_sg_id" {
  value = aws_security_group.endpoint_sg.id
}