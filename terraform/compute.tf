# ---------------------------------------------------------------------------
# Look up your public IP so the Bastion SG only allows SSH from you
# ---------------------------------------------------------------------------
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

locals {
  my_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}

# ---------------------------------------------------------------------------
# Latest Ubuntu 22.04 AMI
# ---------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# Security Groups
# ---------------------------------------------------------------------------

# Bastion: SSH from your IP only
resource "aws_security_group" "bastion" {
  name        = "${var.project}-bastion-sg"
  description = "SSH from my IP to bastion"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-bastion-sg" }
}

# Private app EC2: SSH only from bastion; NodePort range from ALB SG
resource "aws_security_group" "app" {
  name        = "${var.project}-app-sg"
  description = "SSH from bastion, NodePort from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  ingress {
    description     = "NodePort range from ALB"
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project}-app-sg" }
}

# ALB: HTTP from the internet
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "HTTP from internet to ALB"
  vpc_id      = aws_vpc.main.id

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
  tags = { Name = "${var.project}-alb-sg" }
}

# ---------------------------------------------------------------------------
# Bastion host (public subnet, small)
# ---------------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = { Name = "${var.project}-bastion" }
}

# ---------------------------------------------------------------------------
# Private app EC2 (private subnet, runs Kind) - user-data installs everything
# ---------------------------------------------------------------------------
resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 20
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -e
    apt-get update
    # Docker
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu
    # kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -m 0755 kubectl /usr/local/bin/kubectl
    # kind
    curl -Lo kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
    install -m 0755 kind /usr/local/bin/kind
    # create cluster as ubuntu user
    su - ubuntu -c "kind create cluster --name ${var.project}"
  USERDATA

  tags = { Name = "${var.project}-app" }
}
