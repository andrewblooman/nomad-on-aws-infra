output "public_zone_id" {
  description = "The ID of the public hosted zone"
  value       = aws_route53_zone.public.zone_id
}

output "private_zone_id" {
  description = "The ID of the private hosted zone"
  value       = aws_route53_zone.private.zone_id
}