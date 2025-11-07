terraform {
    required_providers{
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.92"
        }
    }
    required_version = ">= 1.2.0"
}

provider "aws" {
    region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

# VPC
resource "aws_vpc" "vpc-tf" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-simbiosys"
  }
}

# Public Subnet
resource "aws_subnet" "subnet-public-tf" {
  vpc_id     = aws_vpc.vpc-tf.id
  cidr_block = "10.0.0.0/25"

  tags = {
    Name = "subnet-public-simbiosys"
  }
}

# Private Subnet
resource "aws_subnet" "subnet-private-tf" {
  vpc_id     = aws_vpc.vpc-tf.id
  cidr_block = "10.0.0.128/25"

  tags = {
    Name = "subnet-private-simbiosys"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "internet-gateway-tf" {
  vpc_id = aws_vpc.vpc-tf.id
  tags = { Name = "internet-gateway-simbiosys" }
}

# Public Route Table
resource "aws_route_table" "public-rt-tf" {
  vpc_id = aws_vpc.vpc-tf.id
  tags = { Name = "public-rt-simbiosys" }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway-tf.id
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat-gateway-tf" {
  allocation_id = aws_eip.nat-eip-tf.id
  subnet_id     = aws_subnet.subnet-public-tf.id
  tags = { Name = "nat-gateway-simbiosys" }
}

# EIP para o NAT Gateway
resource "aws_eip" "nat-eip-tf" {
  domain = "vpc"
}

# Private Route Table
resource "aws_route_table" "private-rt-tf" {
  vpc_id = aws_vpc.vpc-tf.id
  tags = { Name = "private-rt-simbiosys" }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway-tf.id
  }
}

# Public Security group
resource "aws_security_group" "public-security-group-tf" {
  name   = "public-security-group-simbiosys"
  vpc_id = aws_vpc.vpc-tf.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "private-security-group-tf" {
  name   = "private-security-group-simbiosys"
  vpc_id = aws_vpc.vpc-tf.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 3306
    to_port     = 3306
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