output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.nomad_alb.dns_name
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.nomad_tg.arn
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.nomad_alb.arn
}

output "alb_listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.nomad_https.arn
}