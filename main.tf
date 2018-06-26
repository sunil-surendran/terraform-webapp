provider "aws" {
  region = "us-west-2"
}

# VPC

resource "aws_vpc" "sunil-tf-vpc" {
  count                = "${var.create_vpc ? 1 : 0}"
  cidr_block           = "${var.cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"

  tags {
    Name           = "sunil-tf1-vpc"
    Owner          = "sunil.surendran"
    ExpirationDate = "2018-06-30"
    Project        = "Learning"
    Environment    = "Testing"
  }
}

# INTERNET GATEWAY

resource "aws_internet_gateway" "sunil-tf-igw" {
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
}

# SUBNET CONFIGURATION

resource "aws_subnet" "public_a" {
  availability_zone       = "us-west-2a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"

  tags {
    Name = "sunil-tf-pub-A"
  }
}

resource "aws_subnet" "public_b" {
  availability_zone       = "us-west-2b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"

  tags {
    Name = "sunil-tf-pub-B"
  }
}

resource "aws_subnet" "private_a" {
  availability_zone       = "us-west-2a"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"

  tags {
    Name = "sunil-tf-pri-A"
  }
}

resource "aws_subnet" "private_b" {
  availability_zone       = "us-west-2b"
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"

  tags {
    Name = "sunil-tf-pri-B"
  }
}

# ROUTE TABLE CONFIGURATION

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
}

resource "aws_route" "public_route" {
  route_table_id         = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.sunil-tf-igw.id}"
}

resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
}

resource "aws_security_group" "bastion_security" {
    name = "bastion_security"
    description = "Allow SSH access to bastion"
    vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
    ingress {
      from_port = 22
      to_port = 22
      protocol =  "tcp"
      cidr_blocks = ["${var.secure_ip}"]
    }
    egress {
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
      from_port = 0
      to_port = 0
    }
    tags {
      Name = "sunil_bastion_sg"
    }
}

resource "aws_security_group" "webserver_security" {
  name = "webserver_security"
  description = "Allow SSH & HTTP access to VPC CIDR"
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  egress {
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
  tags {
    Name = "sunil_instance_sg"
  }
}
  
resource "aws_security_group" "nat_security" {
  name = "nat_security"
  description = "Access to internet for private instance"
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  egress {
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
  tags {
    Name = "sunil_nat_sg"
  }
}

