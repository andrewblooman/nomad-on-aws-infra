# Output the Windows bastion details
output "windows_bastion_public_ip" {
  description = "Public IP address of the Windows bastion"
  value       = aws_eip.windows_bastion_eip.public_ip
}

output "windows_bastion_instance_id" {
  description = "Instance ID of the Windows bastion"
  value       = aws_instance.windows_bastion.id
}

output "windows_bastion_password_data" {
  description = "Encrypted password data for the Windows bastion (decrypt using your private key)"
  value       = aws_instance.windows_bastion.password_data
}