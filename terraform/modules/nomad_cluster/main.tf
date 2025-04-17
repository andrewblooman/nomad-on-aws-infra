# modules/nomad_cluster/main.tf

# Fetch latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# IAM Role for EC2 instances with minimal permissions
resource "aws_iam_role" "nomad_instance_role" {
  name = "${var.cluster_name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-instance-role"
  }
}

# Attach SSM policy for remote management (optional)
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.nomad_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "nomad_instance_profile" {
  name = "${var.cluster_name}-instance-profile"
  role = aws_iam_role.nomad_instance_role.name
}

# EC2 instances for Nomad servers
resource "aws_instance" "nomad_server" {
  count = var.server_count

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.server_instance_type
  key_name      = var.key_name
  
  subnet_id              = element(var.private_subnets, count.index % length(var.private_subnets))
  vpc_security_group_ids = [var.nomad_server_sg_id]
  
  iam_instance_profile = aws_iam_instance_profile.nomad_instance_profile.name
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # This enforces the use of IMDSv2
    http_put_response_hop_limit = 1
  }
  
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name      = "${var.cluster_name}-server-${count.index + 1}"
    NomadRole = "server"
  }
}

# EC2 instances for Nomad clients
resource "aws_instance" "nomad_client" {
  count = var.client_desired_size

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.client_instance_type
  key_name      = var.key_name
  
  subnet_id              = element(var.private_subnets, count.index % length(var.private_subnets))
  vpc_security_group_ids = [var.nomad_client_sg_id]
  
  iam_instance_profile = aws_iam_instance_profile.nomad_instance_profile.name
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # This enforces the use of IMDSv2
    http_put_response_hop_limit = 1
  }
  
  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name      = "${var.cluster_name}-client-${count.index + 1}"
    NomadRole = "client"
  }
}

# Internal Network Load Balancer for Nomad server discovery
resource "aws_lb" "internal_nlb" {
  name               = "${var.cluster_name}-internal-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnets

  tags = {
    Name = "${var.cluster_name}-internal-nlb"
  }
}

# Target group for internal NLB
resource "aws_lb_target_group" "nomad_internal" {
  name     = "${var.cluster_name}-internal-tg"
  port     = 4647
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "TCP"
    port                = 4647
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name = "${var.cluster_name}-internal-tg"
  }
}

# Register server instances with internal NLB target group
resource "aws_lb_target_group_attachment" "nomad_server_internal" {
  count            = var.server_count
  target_group_arn = aws_lb_target_group.nomad_internal.arn
  target_id        = aws_instance.nomad_server[count.index].id
  port             = 4647
}

# Register server instances with external ALB target group if provided
resource "aws_lb_target_group_attachment" "nomad_server_external" {
  count            = var.alb_target_group_arn != "" ? var.server_count : 0
  target_group_arn = var.alb_target_group_arn
  target_id        = aws_instance.nomad_server[count.index].id
  port             = 4646  # Nomad HTTP API port
}

# Listener for internal NLB
resource "aws_lb_listener" "nomad_internal" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port              = 4647
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nomad_internal.arn
  }
}

# Route53 records for Nomad servers with FQDN
resource "aws_route53_record" "nomad_servers" {
  count   = var.server_count
  zone_id = var.private_zone_id
  name    = "${var.cluster_name}-server-${count.index + 1}.internal.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.nomad_server[count.index].private_ip]
}

# Route53 records for Nomad clients with FQDN
resource "aws_route53_record" "nomad_clients" {
  count   = var.client_desired_size
  zone_id = var.private_zone_id
  name    = "${var.cluster_name}-client-${count.index + 1}.internal.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.nomad_client[count.index].private_ip]
}

# Create a Route53 record for internal Nomad service discovery
resource "aws_route53_record" "nomad_internal" {
  zone_id = var.private_zone_id
  name    = "nomad.internal.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.internal_nlb.dns_name
    zone_id                = aws_lb.internal_nlb.zone_id
    evaluate_target_health = true
  }
}