#######################################
# VPC NETWORK
#######################################
resource "aws_vpc" "petrus" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "${var.project}-${var.environment}-vpc"
  }
}

#######################################
# SUBNET
#######################################
resource "aws_subnet" "petrus" {
  vpc_id     = aws_vpc.petrus.id
  cidr_block = var.subnet_cidr

  tags = {
    Name = "${var.project}-${var.environment}-subnet"
  }
}

#######################################
# INTERNET-GATEWAY
#######################################
resource "aws_internet_gateway" "petrus" {
  vpc_id = aws_vpc.petrus.id

  tags = {
    Name = "${var.project}-${var.environment}-gw"
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
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }
  tags = {
    Name = "${var.project}-${var.environment}-rt"
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
    Name = "${var.project}-${var.environment}-sg"
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
