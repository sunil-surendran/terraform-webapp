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
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.sunil-tf-igw.id}"
  }
  tags {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.sunil_nat.id}"
  }
  tags {
    Name = "private_route_table"
  }
}

# SUBNET-ROUTE TABLE ASSOCIATION

resource "aws_route_table_association" "public_a" {
  subnet_id = "${aws_subnet.public_a.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "public_b" {
  subnet_id = "${aws_subnet.public_b.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "private_a" {
  subnet_id = "${aws_subnet.private_a.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_route_table_association" "private_b" {
  subnet_id = "${aws_subnet.private_b.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}

# SECURITY GROUP CONFIGURATIONS
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
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    security_groups = [ "${aws_security_group.webserver_security.id}" ]
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

# INSTANCE CONFIGURATION

resource "aws_instance" "sunil_bastion" {
  ami = "${var.bastion_ami}"
  availability_zone = "us-west-2a"
  instance_type = "t2.micro"
  key_name = "suniloregonec2"
  vpc_security_group_ids = [ "${aws_security_group.bastion_security.id}" ]
  subnet_id = "${aws_subnet.public_a.id}"
  associate_public_ip_address = "true"
  tags {
    Name           = "sunil_bastion"
    Owner          = "sunil.surendran"
    ExpirationDate = "2018-06-30"
    Project        = "Learning"
    Environment    = "Testing"
  }
}

resource "aws_instance" "sunil_nat" {
  ami = "${var.nat_ami}"
  availability_zone = "us-west-2b"
  instance_type = "t2.micro"
  key_name = "${var.keyname}"
  source_dest_check = "false"
  vpc_security_group_ids = [ "${aws_security_group.nat_security.id}" ]
  subnet_id = "${aws_subnet.public_b.id}"
  associate_public_ip_address = "true"
  tags {
    Name           = "sunil_nat"
    Owner          = "sunil.surendran"
    ExpirationDate = "2018-06-30"
    Project        = "Learning"
    Environment    = "Testing"
  }
}

resource "aws_instance" "sunil_webserver_a" {
  depends_on = [ "aws_instance.sunil_nat" ]
  ami = "${var.webserver_ami}"
  availability_zone = "us-west-2a"
  instance_type = "t2.micro"
  key_name = "${var.keyname}"
  vpc_security_group_ids = [ "${aws_security_group.webserver_security.id}" ]
  subnet_id = "${aws_subnet.private_a.id}"
  associate_public_ip_address = "false"
  tags {
    Name           = "sunil_webservera_a"
    Owner          = "sunil.surendran"
    ExpirationDate = "2018-06-30"
    Project        = "Learning"
    Environment    = "Testing"
  }
  user_data = "${file("userdata.sh")}"
}

resource "aws_instance" "sunil_webserver_b" {
  depends_on = [ "aws_instance.sunil_nat" ]
  ami = "${var.webserver_ami}"
  availability_zone = "us-west-2b"
  instance_type = "t2.micro"
  key_name = "${var.keyname}"
  vpc_security_group_ids = [ "${aws_security_group.webserver_security.id}" ]
  subnet_id = "${aws_subnet.private_b.id}"
  associate_public_ip_address = "false"
  tags {
    Name           = "sunil_webserver_b"
    Owner          = "sunil.surendran"
    ExpirationDate = "2018-06-30"
    Project        = "Learning"
    Environment    = "Testing"
  }
  user_data = "${file("userdata.sh")}"
}
