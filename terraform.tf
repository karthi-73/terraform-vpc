terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "vpc"
  }
}
resource "aws_subnet" "pubs" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone="us-east-1a"

  tags = {
    Name = "public subnet"
  }
}
resource "aws_subnet" "pris" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone="us-east-1b"

  tags = {
    Name = "private subnet"
  }
}
resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "internet gateway"
  }
}
resource "aws_route_table" "pubrt" {
    vpc_id = aws_vpc.myvpc.id
  
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.tigw.id
    }
  
  
    tags = {
      Name = "public route table"
    }
  }
  resource "aws_route_table_association" "pubsass" {
    subnet_id      = aws_subnet.pubs.id
    route_table_id = aws_route_table.pubrt.id
  }
  resource "aws_eip" "teip" {
    vpc      = true
 }
  resource "aws_nat_gateway" "tnat" {
    allocation_id = aws_eip.teip.id
    subnet_id     = aws_subnet.pubs.id
  
    tags = {
      Name = " NAT gw"
    }
 }
 resource "aws_route_table" "prirt" {
    vpc_id = aws_vpc.myvpc.id
  
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.tnat.id
    }
  
  
    tags = {
      Name = "private route table"
    }
  }
  resource "aws_route_table_association" "prisass" {
    subnet_id      = aws_subnet.pris.id
    route_table_id = aws_route_table.prirt.id
  }
  resource "aws_security_group" "pubsg" {
    name        = "pubsg"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_vpc.myvpc.id
  
    ingress {
      description      = "TLS from VPC"
      from_port        = 3389
      to_port          = 3389
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
    tags = {
      Name = "public sec grp"
    }
  }
  resource "aws_security_group" "prisg" {
    name        = "prisg"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_vpc.myvpc.id
  
    ingress {
      description      = "TLS from VPC"
      from_port        = 0
      to_port          = 65535
      protocol         = "tcp"
      cidr_blocks      = ["10.0.1.0/24"]
    }
  
    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }
  
    tags = {
      Name = "private sec grp"
    }
  }
  resource "aws_instance" "pubinstance" {
    ami                                             = "ami-0790e5ec3f7516261"
    instance_type                                   = "t2.micro"
    availability_zone                               = "us-east-1a"
    associate_public_ip_address                     = "true"
    vpc_security_group_ids                          = [aws_security_group.pubsg.id]
    subnet_id                                       = aws_subnet.pubs.id
    key_name                                        = "pemmm"
  
      tags = {
      Name = "public instance"
    }
  }
  
  resource "aws_instance" "priinstance" {
    ami                                             = "ami-0790e5ec3f7516261"
    instance_type                                   = "t2.micro"
    availability_zone                               = "us-east-1b"
    associate_public_ip_address                     = "false"
    vpc_security_group_ids                          = [aws_security_group.prisg.id]
    subnet_id                                       = aws_subnet.pris.id
    key_name                                        = "pemmm"
  
      tags = {
      Name = "private instance"
    }
  }
