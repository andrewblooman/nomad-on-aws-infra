# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for the Nomad ALB"
  vpc_id      = var.vpc_id

  # Keep the rules defined within the security group
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

  # Add lifecycle meta-argument to prevent unnecessary recreation
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

# Security Group for Nomad Servers (empty to start)
resource "aws_security_group" "nomad_server_sg" {
  name        = "${var.cluster_name}-server-sg"
  description = "Security group for Nomad servers"
  vpc_id      = var.vpc_id

  # Just define egress rules - we'll add ingress with separate rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-server-sg"
  }
}

# Security Group for Nomad Clients (empty to start)
resource "aws_security_group" "nomad_client_sg" {
  name        = "${var.cluster_name}-client-sg"
  description = "Security group for Nomad clients"
  vpc_id      = var.vpc_id

  # Just define egress rules - we'll add ingress with separate rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-client-sg"
  }
}

# Endpoint security group
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

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.cluster_name}-endpoint-sg"
  }
}

# Now add all the rules as separate resources to avoid circular references

# Server self-referencing rules
resource "aws_security_group_rule" "server_serf_tcp_self" {
  security_group_id = aws_security_group.nomad_server_sg.id
  type              = "ingress"
  from_port         = 4648
  to_port           = 4648
  protocol          = "tcp"
  self              = true
  description       = "Nomad Serf TCP"
}

resource "aws_security_group_rule" "server_serf_udp_self" {
  security_group_id = aws_security_group.nomad_server_sg.id
  type              = "ingress"
  from_port         = 4648
  to_port           = 4648
  protocol          = "udp"
  self              = true
  description       = "Nomad Serf UDP"
}

resource "aws_security_group_rule" "server_rpc_self" {
  security_group_id = aws_security_group.nomad_server_sg.id
  type              = "ingress"
  from_port         = 4647
  to_port           = 4647
  protocol          = "tcp"
  self              = true
  description       = "Nomad RPC (server to server)"
}

# Server from ALB
resource "aws_security_group_rule" "server_http_from_alb" {
  security_group_id        = aws_security_group.nomad_server_sg.id
  type                     = "ingress"
  from_port                = 4646
  to_port                  = 4646
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Nomad HTTP from ALB"
}

# Server SSH
resource "aws_security_group_rule" "server_ssh" {
  security_group_id = aws_security_group.nomad_server_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "SSH"
}

# Client dynamic ports
resource "aws_security_group_rule" "client_dynamic_ports" {
  security_group_id = aws_security_group.nomad_client_sg.id
  type              = "ingress"
  from_port         = 20000
  to_port           = 32000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow dynamic ports for Nomad tasks"
}

# Client SSH
resource "aws_security_group_rule" "client_ssh" {
  security_group_id = aws_security_group.nomad_client_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "SSH"
}

# Cross-communication between client and server
resource "aws_security_group_rule" "server_from_client" {
  security_group_id        = aws_security_group.nomad_server_sg.id
  type                     = "ingress"
  from_port                = 4647
  to_port                  = 4647
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nomad_client_sg.id
  description              = "Allow Nomad RPC from clients"
}

resource "aws_security_group_rule" "client_from_server" {
  security_group_id        = aws_security_group.nomad_client_sg.id
  type                     = "ingress"
  from_port                = 4647
  to_port                  = 4647
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nomad_server_sg.id
  description              = "Allow Nomad RPC from servers"
}