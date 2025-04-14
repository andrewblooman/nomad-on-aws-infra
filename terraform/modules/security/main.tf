# modules/security/main.tf

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for the Nomad ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

# Security Group for Nomad Servers (core settings only)
resource "aws_security_group" "nomad_server_sg" {
  name        = "${var.cluster_name}-server-sg"
  description = "Security group for Nomad servers"
  vpc_id      = var.vpc_id

  # Self-referencing rules (server to server communication)
  ingress {
    description = "Nomad Serf TCP"
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Nomad Serf UDP"
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    self        = true
  }

  # From ALB
  ingress {
    description     = "Nomad HTTP"
    from_port       = 4646
    to_port         = 4646
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Self-referencing RPC
  ingress {
    description = "Nomad RPC (server to server)"
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-server-sg"
  }
}

# Security Group for Nomad Clients (core settings only)
resource "aws_security_group" "nomad_client_sg" {
  name        = "${var.cluster_name}-client-sg"
  description = "Security group for Nomad clients"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow dynamic ports for Nomad tasks"
    from_port   = 20000
    to_port     = 32000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-client-sg"
  }
}

# Additional security group rules to break circular dependencies

# Server access from client
resource "aws_security_group_rule" "server_from_client" {
  security_group_id        = aws_security_group.nomad_server_sg.id
  type                     = "ingress"
  from_port                = 4647
  to_port                  = 4647
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nomad_client_sg.id
  description              = "Allow Nomad RPC from clients"
}

# Client access from server
resource "aws_security_group_rule" "client_from_server" {
  security_group_id        = aws_security_group.nomad_client_sg.id
  type                     = "ingress"
  from_port                = 4647
  to_port                  = 4647
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nomad_server_sg.id
  description              = "Allow Nomad RPC from servers"
}

# Add to your security module (modules/security/main.tf)
resource "aws_security_group" "endpoint_sg" {
  name        = "${var.cluster_name}-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-endpoint-sg"
  }
}