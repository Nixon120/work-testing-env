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

variable "subnet_names" { 
  type = list
  default = ["mirth-private1", "mirth-private2", "mirth-private3"]
   }
