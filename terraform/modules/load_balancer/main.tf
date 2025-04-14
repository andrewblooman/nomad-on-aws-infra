# Application Load Balancer
resource "aws_lb" "nomad_alb" {
  name               = "nomad-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "nomad-alb"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "nomad_tg" {
  name     = "nomad-tg"
  port     = 4646
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/v1/agent/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  tags = {
    Name = "nomad-target-group"
  }
}

# ALB Listener
resource "aws_lb_listener" "nomad_https" {
  load_balancer_arn = aws_lb.nomad_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nomad_tg.arn
  }
}

# ALB HTTP to HTTPS Redirect
resource "aws_lb_listener" "nomad_http" {
  load_balancer_arn = aws_lb.nomad_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Route53 Record for ALB
resource "aws_route53_record" "nomad" {
  zone_id = var.public_zone_id
  name    = var.nomad_domain
  type    = "A"

  alias {
    name                   = aws_lb.nomad_alb.dns_name
    zone_id                = aws_lb.nomad_alb.zone_id
    evaluate_target_health = true
  }
}
