# Windows Bastion Server Configuration

# Get the latest Windows Server 2022 AMI
data "aws_ami" "windows_server" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a security group for the Windows bastion
resource "aws_security_group" "windows_bastion_sg" {
  name        = "${var.cluster_name}-windows-bastion-sg"
  description = "Security group for Windows bastion server"
  vpc_id      = var.vpc_id

  # Allow RDP access from your IP address
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]  # Replace with your specific IP address
    description = "Allow RDP from my IP"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.cluster_name}-windows-bastion-sg"
  }
}

# Create an IAM role for the Windows bastion
resource "aws_iam_role" "windows_bastion_role" {
  name = "${var.cluster_name}-windows-bastion-role"

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
    Name = "${var.cluster_name}-windows-bastion-role"
  }
}

# Attach the SSM policy to the role (for easy session management)
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.windows_bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create an instance profile for the Windows bastion
resource "aws_iam_instance_profile" "windows_bastion_profile" {
  name = "${var.cluster_name}-windows-bastion-profile"
  role = aws_iam_role.windows_bastion_role.name
}

# Create the Windows bastion EC2 instance
resource "aws_instance" "windows_bastion" {
  ami                  = data.aws_ami.windows_server.id
  instance_type        = var.bastion_instance_type
  key_name             = var.key_name
  subnet_id            = element(var.public_subnets, 0)
  vpc_security_group_ids = [aws_security_group.windows_bastion_sg.id]
  iam_instance_profile = aws_iam_instance_profile.windows_bastion_profile.name
  
  # Get the administrator password using the key pair
  get_password_data    = true

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  # Enable IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = <<EOF
<powershell>
# Rename the computer
Rename-Computer -NewName "WindowsBastion" -Force

# Configure Windows Firewall to allow RDP
Set-NetFirewallRule -Name RemoteDesktop-UserMode-In-TCP -Enabled True

# Enable Remote Desktop
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Install common tools
# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install some useful tools
choco install -y awscli
choco install -y vscode
choco install -y 7zip
choco install -y chrome-remote-desktop-host
choco install -y pwsh

# Set a scheduled task to check for Windows updates
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command "& {Install-WindowsUpdate -AcceptAll -AutoReboot:$false}"'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
Register-ScheduledTask -TaskName "WindowsUpdates" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "System"

# Restart the computer to apply changes
Restart-Computer -Force
</powershell>
EOF

  tags = {
    Name = "${var.cluster_name}-windows-bastion"
  }
}

# Create an Elastic IP for the Windows bastion
resource "aws_eip" "windows_bastion_eip" {
  instance = aws_instance.windows_bastion.id
  domain   = "vpc"

  tags = {
    Name = "${var.cluster_name}-windows-bastion-eip"
  }
}

# Create a Route53 record for the Windows bastion if needed
resource "aws_route53_record" "windows_bastion" {
  count   = var.create_dns_record ? 1 : 0
  zone_id = var.public_zone_id
  name    = "bastion.${var.domain_name}"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.windows_bastion_eip.public_ip]
}
