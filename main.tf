provider "aws" {
  region = "us-west-2"
}

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