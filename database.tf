/*
#Define data sources to retrieve subnet IDs dynamically
data "aws_subnet" "private_subnet1" {
  vpc_id = var.vpc_id

  tags = {
    Name = "mirth-private1"  # Replace with the name of your first subnet
  }
}

data "aws_subnet" "private_subnet2" {
  vpc_id = var.vpc_id

  tags = {
    Name = "mirth-private2"  # Replace with the name of your second subnet
  }
}

data "aws_subnet" "private_subnet3" {
  vpc_id = var.vpc_id

  tags = {
    Name = "mirth-private3"  # Replace with the name of your third subnet
  }
}

# Define the subnet work group
resource "aws_db_subnet_group" "mirth_subnet_work_group" {
  name = "mirth-subnet-work-group"

  subnet_ids = [
    data.aws_subnet.private_subnet1.id,
    data.aws_subnet.private_subnet2.id,
    data.aws_subnet.private_subnet3.id
  ]

  tags = {
    Name = "Mirth Subnet Work Group"
  }
}

# Define data source to retrieve secret information from AWS Secrets Manager
data "aws_secretsmanager_secret" "postgres_credentials" {
  name = "postgres_credentials"  # Replace with the name of your AWS Secrets Manager secret
}

# Retrieve the secret version from the secret dynamically
data "aws_secretsmanager_secret_version" "postgres_credentials" {
  secret_id = data.aws_secretsmanager_secret.postgres_credentials.id
}

# Deploy PostgreSQL database instance
resource "aws_db_instance" "prod-mirth-DBInstance" {
  allocated_storage= 100
  identifier= "prod-mirth-db"
  engine= "postgres"
  engine_version= "13.13"
  instance_class= "db.m6i.4xlarge"
  db_subnet_group_name= aws_db_subnet_group.mirth_subnet_work_group.name  # Corrected reference
  publicly_accessible= false
  skip_final_snapshot= true
  multi_az= false
  vpc_security_group_ids = [data.aws_security_group.existing_security_group.id]

  # Retrieve username and password from AWS Secrets Manager (using appropriate keys)
  username = jsondecode(data.aws_secretsmanager_secret_version.postgres_credentials.secret_string).username
  password = jsondecode(data.aws_secretsmanager_secret_version.postgres_credentials.secret_string).password

} */

# Reference your existing security group
data "aws_security_group" "existing_security_group" {
  name = "mirth_security_group"  # Replace with the actual name
}
