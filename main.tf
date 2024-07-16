provider "aws" {
  region = "ap-northeast-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}


resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

# Route Table, like a virtual router
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-rtb"
  }
}

# Terraform knows in which sequence the components must be created
# Internet Gateway, like a virtual modem
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}

# Security Grouo
resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id
  # Incoming Triffic
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.my_ip
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name: "${var.env_prefix}-sg"
  }
}

# EC2 instance
data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-x86_64-gp2" ]
  }
}

output "aws_ami_id" {
  value = data.aws_ami.latest-amazon-linux-image
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    # optional
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [ aws_security_group.myapp-sg.id ]
    availability_zone = var.avail_zone
    associate_public_ip_address = true

    # SSH
    # You need to create key pair via AWS, then mv pem file into ~/.ssh
    # then chmod 400 that pem file
    # AWS rejects ssh request, if permission not set correctly 
    key_name = "server-key-pair"

    tags = {
      Name: "${var.env_prefix}-server"
    }
}