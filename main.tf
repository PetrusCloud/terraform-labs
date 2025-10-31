#######################################
# Provider
#######################################
provider "aws" {
  region = var.aws_region
}

#######################################
# TLS Private Key generate both pub and private
#######################################
resource "tls_private_key" "dylan_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#######################################
# Save Private Key Locally
#######################################
resource "local_file" "dylan_private_key" {
  content  = tls_private_key.dylan_key.private_key_pem
  filename = "dylan237.pem"
}

#######################################
# Create AWS Key Pair
#######################################
resource "aws_key_pair" "dylan_keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.dylan_key.public_key_openssh
}

#######################################
# Get Latest Ubuntu AMI
#######################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#######################################
# EC2 Instance
#######################################
resource "aws_instance" "dylan-ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.dylan_keypair.key_name

  tags = {
    Name = var.instance_name
  }
}
