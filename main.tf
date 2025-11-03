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
  subnet_id              = aws_subnet.petrus.id      # replace with your subnet ID
  vpc_security_group_ids = [aws_security_group.petrus.id]
  depends_on = [aws_subnet.petrus]

  tags = {
    Name = var.instance_name
  }
}

#######################################
# VPC NETWORK
#######################################
resource "aws_vpc" "petrus" {
  cidr_block       = "20.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "petrus-vpc"
  }
}

#######################################
# SUBNET
#######################################
resource "aws_subnet" "petrus" {
  vpc_id     = aws_vpc.petrus.id
  cidr_block = "20.0.0.0/24"

  tags = {
    Name = "public-subnet"
  }
}

#######################################
# INTERNET-GATEWAY
#######################################
resource "aws_internet_gateway" "petrus" {
  vpc_id = aws_vpc.petrus.id

  tags = {
    Name = "petrus-gw"
  }
}

#######################################
# ROUTE-TABLE
#######################################
resource "aws_route_table" "petrus" {
  vpc_id = aws_vpc.petrus.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.petrus.id
  }

  route {
    cidr_block = "20.0.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "example"
  }
}

resource "aws_route_table_association" "petrus" {
  subnet_id      = aws_subnet.petrus.id
  route_table_id = aws_route_table.petrus.id
}

#######################################
# security_group
#######################################

resource "aws_security_group" "petrus" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.petrus.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.petrus.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.petrus.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.petrus.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.petrus.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
