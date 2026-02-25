###############################################
# Project - MicroK8s Monitoring Platform
###############################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

###############################################
# Variables
###############################################

variable "project_name" {
  type    = string
  default = "microk8s-monitoring"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name for SSH access"
}

###############################################
# Data sources
###############################################

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

###############################################
# Security group
###############################################

resource "aws_security_group" "microk8s_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for MicroK8s monitoring host"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana NodePort (we'll use 32000)
  ingress {
    description = "Grafana NodePort"
    from_port   = 32000
    to_port     = 32000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Hello API NodePort"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################################
# EC2 instance
###############################################

resource "aws_instance" "microk8s_host" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.microk8s_sg.id]

  subnet_id = data.aws_subnets.default.ids[0]

  user_data = file("${path.module}/../scripts/bootstrap.sh")

  root_block_device {
    volume_size = 16
  }

  tags = {
    Name = "${var.project_name}-host"
  }
}

###############################################
# Outputs
###############################################

output "instance_public_ip" {
  value = aws_instance.microk8s_host.public_ip
}

output "instance_public_dns" {
  value = aws_instance.microk8s_host.public_dns
}
