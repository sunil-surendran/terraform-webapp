provider "aws" {
  region = "us-west-2"
}



# VPC

resource "aws_vpc" "sunil-tf-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags {
    Name = "sunil-tf1-vpc"
    Owner = "sunil.surendran"
    ExpirationDate = "2018-06-30"
    Project = "Learning"
    Environment = "Testing"
  }
}

# INTERNET GATEWAY

resource "aws_internet_gateway" "sunil-tf-igw" {
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
}

# SUBNET CONFIGURATION

resource "aws_subnet" "public_a" {
  availability_zone = "us-west-2a"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
  tags {
    Name = "sunil-tf-pub-A"
  }
}

resource "aws_subnet" "public_b" {
  availability_zone = "us-west-2b"
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
  tags {
    Name = "sunil-tf-pub-B"
  }
}

resource "aws_subnet" "private_a" {
  availability_zone = "us-west-2a"
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
  tags {
    Name = "sunil-tf-pri-A"
  }
}

resource "aws_subnet" "private_b" {
  availability_zone = "us-west-2b"
  cidr_block = "10.0.4.0/24"
  map_public_ip_on_launch = false
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
  tags {
    Name = "sunil-tf-pri-B"
  }
}
