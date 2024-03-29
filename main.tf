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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic (adjust for security)
  }
}

# Create a new key pair
resource "aws_key_pair" "mirth_key" {
  key_name   = "mirth_key"  # Name of the new key pair
  public_key = file("~/.ssh/id_rsa.pub")  # Path to the public key file
}

# Create a new public subnet, specifying a valid availability zone
resource "aws_subnet" "mirth_public_subnet" {
  availability_zone       = "us-east-1a"  # Replace with a valid zone in your region
  cidr_block              = "10.0.0.32/28"
  vpc_id                  = data.aws_vpc.existing_vpc.id
  map_public_ip_on_launch = true
}

# Create a route table for the public subnet with a route to the IGW
resource "aws_route_table" "mirth_public_route_table" {
  vpc_id = data.aws_vpc.existing_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mirth_igw.id
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
  key_name               = aws_key_pair.mirth_key.key_name  # Use the new key pair
   
  root_block_device {
    volume_size           = 200  # 150GB for the root volume
    volume_type           = "gp2"  # General Purpose SSD (gp2) volume type
    delete_on_termination = false
  }

  tags = {
    Name = "Mirth-Application"
  }
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