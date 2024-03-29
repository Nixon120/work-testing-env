
/*
 Copyright © 2024 Radiology Partners, Inc. - All Rights Reserved
 Unauthorized copying of this file, via any medium is strictly prohibited
 Proprietary and confidential
 */

 
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_access_key
}

variable "aws_secret_access_key" {
  description = "The AWS secret key"
  type        = string
}

variable "aws_access_key" {
  description = "The AWS access key"
  type        = string
}

terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}