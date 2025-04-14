output "server_asg_name" {
  description = "Name of the Nomad server Auto Scaling Group"
  value       = aws_autoscaling_group.nomad_server.name
}

output "client_asg_name" {
  description = "Name of the Nomad client Auto Scaling Group"
  value       = aws_autoscaling_group.nomad_client.name
}

output "server_launch_template_id" {
  description = "ID of the Nomad server launch template"
  value       = aws_launch_template.nomad_server.id
}

output "client_launch_template_id" {
  description = "ID of the Nomad client launch template"
  value       = aws_launch_template.nomad_client.id
}