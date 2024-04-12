
# Copyright © 2024 Radiology Partners, Inc. - All Rights Reserved
# Unauthorized copying of this file, via any medium is strictly prohibited
# Proprietary and confidential

# Retrieve information about the existing VPC using input variable
data "aws_vpc" "existing_vpc" {
  id = var.vpc_id
}

# Create an internet gateway
resource "aws_internet_gateway" "mirth_igw" {
  vpc_id = data.aws_vpc.existing_vpc.id
}

# Create a security group allowing SSH access from anywhere
resource "aws_security_group" "mirth_security_group" {
  name        = "mirth_security_group"
  description = "Security group for Mirth application instance"
  vpc_id      = data.aws_vpc.existing_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (adjust for security)
  }

  # Define ingress rules for additional ports
  ingress {
    from_port   = 4242
    to_port     = 4246
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["234.819.23.0/23","34.90.09.67/16"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

# Retrieve existing key pair
data "aws_key_pair" "existing_key_pair" {
  key_name = "mirth_key"  # Name of the existing key pair
}

# Create a new public subnet
resource "aws_subnet" "mirth_public_subnet" {
  availability_zone       = "us-east-1a"  # Replace with a valid zone in your region
  cidr_block              = var.subnet_cidr_block  # Using the subnet_cidr_block variable
  vpc_id                  = data.aws_vpc.existing_vpc.id
  map_public_ip_on_launch = true
}

# Create a route table for the public subnet
resource "aws_route_table" "mirth_public_route_table" {
  vpc_id = data.aws_vpc.existing_vpc.id

  # Route to the Internet Gateway for internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mirth_igw.id
  }

  # Route to the Transit Gateway for specific traffic
  route {
    cidr_block         = "10.218.96.0/23"
    transit_gateway_id = var.transit_gateway_id  # Corrected to use transit_gateway_id
  }
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.mirth_public_subnet.id
  route_table_id = aws_route_table.mirth_public_route_table.id
}

# Define the latest Ubuntu AMI as a data source
data "aws_ami" "latest_ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical
}

# Launch a new EC2 instance
resource "aws_instance" "mirth_application" {
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.mirth_security_group.id]
  subnet_id              = aws_subnet.mirth_public_subnet.id
  key_name               = data.aws_key_pair.existing_key_pair.key_name

  root_block_device {
    volume_size           = 200
    volume_type           = "gp2"
    delete_on_termination = false
  }

  tags = {
    Name = "Mirth-Application"
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y default-jre
    curl -O https://s3.amazonaws.com/downloads.mirthcorp.com/connect/4.5.0.b3012/mirthconnect-4.5.0.b3012-unix.tar.gz
    tar -xvzf mirthconnect-4.5.0.b3012-unix.tar.gz
    sudo mv Mirth Connect /opt/mirthconnect
  EOF
}

# Allocate an Elastic IP address
resource "aws_eip" "mirth_eip" {
  vpc = true
}

# Associate the Elastic IP with the EC2 instance
resource "aws_eip_association" "mirth_eip_assoc" {
  instance_id   = aws_instance.mirth_application.id
  allocation_id = aws_eip.mirth_eip.id
}


