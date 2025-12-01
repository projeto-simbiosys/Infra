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

variable "instance-type" {
  description = "Tipo de instância EC2."
  type        = string
  default     = "t2.micro"
}

variable "key-pair-name" {
  description = "Nome do par de chaves para acessar as instâncias EC2."
  type        = string
  default     = "key_simbiosys"
}

# Key PEM
resource "aws_key_pair" "generated-key" {
  key_name   = var.key-pair-name
  public_key = file("key_simbiosys.pem.pub")
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

resource "aws_route_table_association" "public-rt-assoc-tf" {
  subnet_id      = aws_subnet.subnet-public-tf.id
  route_table_id = aws_route_table.public-rt-tf.id
}

# NAT Gateway
resource "aws_nat_gateway" "nat-gateway-tf" {
  allocation_id = aws_eip.nat-eip-tf.id
  subnet_id     = aws_subnet.subnet-public-tf.id
  tags = { Name = "nat-gateway-simbiosys" }
}

# IP Elástico para o NAT Gateway
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

resource "aws_route_table_association" "private-rt-assoc-tf" {
  subnet_id      = aws_subnet.subnet-private-tf.id
  route_table_id = aws_route_table.private-rt-tf.id
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
    from_port   = 8082
    to_port     = 8082
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

# IP Elástico do proxy reverso
resource "aws_eip" "eip-tf" {
  domain = "vpc"

  instance = aws_instance.reverse-proxy-tf.id

  tags = {
    Name = "eip-simbiosys"
  }
}

# Instância do proxy reverso / load balancer
resource "aws_instance" "reverse-proxy-tf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.subnet-public-tf.id
  vpc_security_group_ids      = [aws_security_group.public-security-group-tf.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.generated-key.key_name

  # Lê script de configuração
  user_data = file("${path.module}/scripts/setup_reverse_proxy_nginx.sh")

  tags = {
    Name = "reverse-proxy-simbiosys"
  }
}

resource "aws_instance" "front-instance-1-tf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.subnet-private-tf.id
  vpc_security_group_ids      = [aws_security_group.private-security-group-tf.id]
  associate_public_ip_address = false
  private_ip                  = "10.0.0.135"
  key_name                    = aws_key_pair.generated-key.key_name

  # Lê script de configuração
  user_data = file("${path.module}/scripts/setup_frontend.sh")

  tags = {
    Name = "front-instance-1-simbiosys"
  }

}

resource "aws_instance" "front-instance-2-tf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.subnet-private-tf.id
  vpc_security_group_ids      = [aws_security_group.private-security-group-tf.id]
  associate_public_ip_address = false
  private_ip                  = "10.0.0.136"
  key_name                    = aws_key_pair.generated-key.key_name

  # Lê script de configuração
  user_data = file("${path.module}/scripts/setup_frontend.sh")

  tags = {
    Name = "front-instance-2-simbiosys"
  }

}

resource "aws_instance" "back-instance-1-tf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.subnet-private-tf.id
  vpc_security_group_ids      = [aws_security_group.private-security-group-tf.id]
  associate_public_ip_address = false
  private_ip                  = "10.0.0.235"
  key_name                    = aws_key_pair.generated-key.key_name

  # Lê script de configuração
  user_data = file("${path.module}/scripts/setup_backend.sh")

  tags = {
    Name = "back-instance-1-simbiosys"
  }

}

resource "aws_instance" "back-instance-2-tf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.subnet-private-tf.id
  vpc_security_group_ids      = [aws_security_group.private-security-group-tf.id]
  associate_public_ip_address = false
  private_ip                  = "10.0.0.236"
  key_name                    = aws_key_pair.generated-key.key_name

  # Lê script de configuração
  user_data = file("${path.module}/scripts/setup_backend.sh")

  tags = {
    Name = "back-instance-2-simbiosys"
  }

}

resource "aws_instance" "mysql-instance-tf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.subnet-private-tf.id
  vpc_security_group_ids      = [aws_security_group.private-security-group-tf.id]
  associate_public_ip_address = false
  private_ip                  = "10.0.0.245"
  key_name                    = aws_key_pair.generated-key.key_name

  # Lê script de configuração
  user_data = file("${path.module}/scripts/setup_mysql.sh")

  tags = {
    Name = "mysql-instance-simbiosys"
  }
}

resource "aws_instance" "rabbitmq-instance-tf" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance-type
  subnet_id                   = aws_subnet.subnet-private-tf.id
  vpc_security_group_ids      = [aws_security_group.private-security-group-tf.id]
  associate_public_ip_address = false
  private_ip                  = "10.0.0.246"
  key_name                    = aws_key_pair.generated-key.key_name

  # Lê script de configuração
  user_data = file("${path.module}/scripts/setup_rabbitmq.sh")

  tags = {
    Name = "rabbitmq-instance-simbiosys"
  }

}