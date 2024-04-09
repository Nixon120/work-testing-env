variable "ami_id" {
  description = "ID of the latest Amazon Linux 2 AMI"
  # Replace with the actual AMI ID for your desired OS
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of the existing key pair to use"
}

variable "vpc_id" {
  description = "The ID of the existing VPC"
  type        = string
}

variable "subnet_cidr_block" {
  description = "CIDR block for the new subnet"
  type        = string
}  

variable "transit_gateway_id {
   description = "ID of the transit gateway"
   type        = string
}
