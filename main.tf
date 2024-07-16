provider "aws" {
  region = "ap-northeast-1"
}

variable "environment" {
    description = "Deploy Environment"
    default = "development"
    type = string
  
}
variable "cidr_blocks" {
    description = "Cidr Block List, 1st for VPC, 2nd for subnet"
    type = list(object({
        cidr_block = string
        name = string
    }))
}
# variable "avail_zone" {}


resource "aws_vpc" "development-vpc" {
  cidr_block = var.cidr_blocks[0].cidr_block
  tags = {
    Name: var.cidr_blocks[0].name
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.cidr_blocks[1].cidr_block
  availability_zone = "ap-northeast-1a"
  # Need to export TF_VAR_avail_zone="ap-northeast-1a"
  # availability_zone = var.avail_zone
  tags = {
    Name: var.cidr_blocks[1].name
  }
}

data "aws_vpc" "existing_vpc" {
  default = true
}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id = data.aws_vpc.existing_vpc.id
  cidr_block = "172.31.48.0/20"
  # availability_zone = var.avail_zone
  availability_zone = "ap-northeast-1a"
  tags = {
    Name: "subnet-default-4"
  }
}

output "dev-vpc-id" {
  value = aws_vpc.development-vpc.id
}
output "dev-subnet-id" {
  value = aws_subnet.dev-subnet-1.id
}