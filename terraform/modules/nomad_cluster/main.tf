# modules/nomad_cluster/main.tf

# S3 bucket for bootstrap scripts
resource "aws_s3_bucket" "bootstrap" {
  bucket = "${var.cluster_name}-bootstrap-${random_string.suffix.result}"

  tags = {
    Name = "${var.cluster_name}-bootstrap"
  }
}

# Random suffix to ensure unique bucket names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "bootstrap" {
  bucket = aws_s3_bucket.bootstrap.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload the Nomad setup script to S3
resource "aws_s3_object" "nomad_setup_script" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "scripts/nomad-setup.sh"
  source = "${path.module}/scripts/nomad-setup.sh" # Path to your local script
  etag   = filemd5("${path.module}/scripts/nomad-setup.sh")
}

# Fetch latest Bottlerocket AMI
data "aws_ami" "bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-*-x86_64-*"]
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

# IAM Role for EC2 instances
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

# IAM Policy for EC2 instances
resource "aws_iam_policy" "nomad_instance_policy" {
  name        = "${var.cluster_name}-instance-policy"
  description = "Policy for Nomad cluster instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.bootstrap.arn,
          "${aws_s3_bucket.bootstrap.arn}/*"
        ]
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.region}:*:parameter/bottlerocket/*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "nomad_instance_policy_attachment" {
  role       = aws_iam_role.nomad_instance_role.name
  policy_arn = aws_iam_policy.nomad_instance_policy.arn
}

# Instance profile
resource "aws_iam_instance_profile" "nomad_instance_profile" {
  name = "${var.cluster_name}-instance-profile"
  role = aws_iam_role.nomad_instance_role.name
}

# SSM Parameter for Nomad server config
resource "aws_ssm_parameter" "nomad_server_config" {
  name = "/nomad/${var.cluster_name}/server-config"
  type = "String"
  value = jsonencode({
    settings = {
      "host-containers" = {
        "admin" = {
          "enabled"      = true,
          "superpowered" = true
        }
      },
      "nomad" = {
        "datacenter"       = "dc1",
        "server"           = true,
        "bootstrap_expect" = var.server_count,
        "enabled"          = true,
        "oidc" = {
          "enabled"          = true,
          "discovery_url"    = "${var.api_url}/.well-known/openid-configuration",
          "discovery_ca_pem" = "",
          "workspace_url"    = var.api_url,
          "signing_algs"     = ["RS256"],
          "client_id"        = "nomad",
          "claim_mappings" = {
            "email" = "email"
          },
          "bound_audiences" = ["nomad"],
          "scopes"          = ["openid", "email"]
        }
      }
    }
  })
}

# SSM Parameter for Nomad client config
resource "aws_ssm_parameter" "nomad_client_config" {
  name = "/nomad/${var.cluster_name}/client-config"
  type = "String"
  value = jsonencode({
    settings = {
      "host-containers" = {
        "admin" = {
          "enabled"      = true,
          "superpowered" = true
        }
      },
      "nomad" = {
        "datacenter" = "dc1",
        "client"     = true,
        "enabled"    = true,
        "server_join" = {
          "retry_join" = ["provider=aws tag_key=NomadRole tag_value=server"]
        }
      }
    }
  })
}

# Create Bottlerocket user data for Nomad servers
locals {
  server_user_data = <<EOF
[settings]
[settings.host-containers.admin]
enabled = true
superpowered = true

[settings.bootstrap-containers.nomad-setup]
source = "amazon/bottlerocket-bootstrap:1.0"
mode = "always"
essential = true
environment = ["BOOTSTRAP_SCRIPT_URL=s3://${aws_s3_bucket.bootstrap.id}/scripts/nomad-setup.sh", "NOMAD_ROLE=server"]
EOF

  client_user_data = <<EOF
[settings]
[settings.host-containers.admin]
enabled = true
superpowered = true

[settings.bootstrap-containers.nomad-setup]
source = "amazon/bottlerocket-bootstrap:1.0"
mode = "always"
essential = true
environment = ["BOOTSTRAP_SCRIPT_URL=s3://${aws_s3_bucket.bootstrap.id}/scripts/nomad-setup.sh", "NOMAD_ROLE=client"]
EOF
}

# Launch template for Nomad servers
resource "aws_launch_template" "nomad_server" {
  name_prefix   = "${var.cluster_name}-server-"
  image_id      = data.aws_ami.bottlerocket.id
  instance_type = var.server_instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.nomad_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.nomad_server_sg_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 50
      volume_type = "gp3"
    }
  }

  user_data = base64encode(local.server_user_data)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "${var.cluster_name}-server"
      NomadRole = "server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Launch template for Nomad clients
resource "aws_launch_template" "nomad_client" {
  name_prefix   = "${var.cluster_name}-client-"
  image_id      = data.aws_ami.bottlerocket.id
  instance_type = var.client_instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.nomad_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.nomad_client_sg_id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 100
      volume_type = "gp3"
    }
  }

  user_data = base64encode(local.client_user_data)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name      = "${var.cluster_name}-client"
      NomadRole = "client"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for Nomad servers
resource "aws_autoscaling_group" "nomad_server" {
  name                = "${var.cluster_name}-server"
  desired_capacity    = var.server_count
  min_size            = var.server_count
  max_size            = var.server_count
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.nomad_server.id
    version = "$Latest"
  }

  # Register with ALB target group
  target_group_arns = [var.alb_target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "NomadRole"
    value               = "server"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for Nomad clients
resource "aws_autoscaling_group" "nomad_client" {
  name                = "${var.cluster_name}-client"
  desired_capacity    = var.client_desired_size
  min_size            = var.client_min_size
  max_size            = var.client_max_size
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.nomad_client.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-client"
    propagate_at_launch = true
  }

  tag {
    key                 = "NomadRole"
    value               = "client"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a Route53 record for internal Nomad discovery
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

# Register server ASG with internal NLB
resource "aws_autoscaling_attachment" "nomad_server_internal" {
  autoscaling_group_name = aws_autoscaling_group.nomad_server.name
  lb_target_group_arn    = aws_lb_target_group.nomad_internal.arn
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