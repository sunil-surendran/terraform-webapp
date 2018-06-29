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
  count  = "${var.create_vpc ? 1 : 0}"
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
}

# SUBNET CONFIGURATION
resource "aws_subnet" "public" {
  count                   = "${var.create_vpc==1 ? length(var.list_az) : 0 }"
  availability_zone       = "${element(var.list_az, count.index)}"
  cidr_block              = "${element(var.pub_cidr, count.index)}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"
  tags {
    Name = "sunil-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                   = "${var.create_vpc==1 ? length(var.list_az) : 0 }"
  availability_zone       = "${element(var.list_az, count.index)}"
  cidr_block              = "${element(var.priv_cidr, count.index)}"
  map_public_ip_on_launch = false
  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"
  tags {
    Name = "sunil-private-subnet-${count.index + 1}"
  }
}

# ROUTE TABLE CONFIGURATION
resource "aws_route_table" "public_route_table" {
  count  = "${var.create_vpc ? 1 : 0}"
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
  count  = "${var.create_vpc ? 1 : 0}"
  vpc_id = "${aws_vpc.sunil-tf-vpc.id}"
  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = "${aws_instance.sunil_nat.id}"
  }
  tags {
    Name = "private_route_table"
  }
}

# Private route for existing resource
resource "aws_route" "private_r" {
  count                  = "${var.create_vpc ? 0 : 1}"
  route_table_id         = "${var.private_rt}"
  instance_id            = "${aws_instance.sunil_nat.id}"
  destination_cidr_block = "0.0.0.0/0"
}

# SUBNET-ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "public_route" {
  count          = "${var.create_vpc==1 ? length(var.list_az) : 0 }"
  subnet_id      = "${element(concat(aws_subnet.public.*.id, list("")), count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "private_route" {
  count = "${length(var.list_az)}"
  subnet_id = "${var.create_vpc==1 ? element(concat(aws_subnet.private.*.id, list("")), count.index) : element(var.subnet_pri, count.index)}"
  route_table_id = "${var.create_vpc==1 ? join("",  aws_route_table.private_route_table.*.id) : var.private_rt}"
}

# SECURITY GROUP CONFIGURATIONS
resource "aws_security_group" "bastion_security" {
  name        = "bastion_security"
  description = "Allow SSH access to bastion"
  vpc_id      = "${var.create_vpc==1 ? join("", aws_vpc.sunil-tf-vpc.*.id) : var.exist_vpc_id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.secure_ip}"]
  }
  egress {
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
  tags {
    Name = "sunil_bastion_sg"
  }
}

resource "aws_security_group" "webserver_security" {
  name        = "webserver_security"
  description = "Allow SSH & HTTP access to VPC CIDR"
  vpc_id      = "${var.create_vpc==1 ? join("", aws_vpc.sunil-tf-vpc.*.id) : var.exist_vpc_id}"
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  egress {
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
  tags {
    Name = "sunil_instance_sg"
  }
}

resource "aws_security_group" "sunil_elb_sg" {
  name        = "sunil_elb_sg"
  description = "Security group for ELB"
  vpc_id      = "${var.create_vpc==1 ? join("", aws_vpc.sunil-tf-vpc.*.id) : var.exist_vpc_id}"
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["${var.secure_ip}"]
  }
  egress {
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}

resource "aws_security_group" "nat_security" {
  name        = "nat_security"
  description = "Access to internet for private instance"
  vpc_id      = "${var.create_vpc==1 ? join("", aws_vpc.sunil-tf-vpc.*.id) : var.exist_vpc_id}"
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["${var.cidr}"]
  }
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = ["${aws_security_group.webserver_security.id}"]
  }
  egress {
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
  tags {
    Name = "sunil_nat_sg"
  }
}

# INSTANCE CONFIGURATION
resource "aws_instance" "sunil_bastion" {
  ami                         = "${var.bastion_ami}"
  availability_zone           = "${element(var.list_az, 0)}"
  instance_type               = "t2.micro"
  key_name                    = "${var.keyname}"
  vpc_security_group_ids      = ["${aws_security_group.bastion_security.id}"]
  subnet_id                   = "${var.create_vpc==1 ? element(concat(aws_subnet.public.*.id, list("")), 0) : element(var.subnet_pub, 0)}"
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
  ami                    = "${var.nat_ami}"
  availability_zone      = "${element(var.list_az, 1)}"
  instance_type          = "t2.micro"
  key_name               = "${var.keyname}"
  source_dest_check      = "false"
  vpc_security_group_ids = ["${aws_security_group.nat_security.id}"]
  subnet_id              = "${var.create_vpc==1 ? element(concat(aws_subnet.public.*.id, list("")), 1) : element(var.subnet_pub, 1)}"
  associate_public_ip_address = "true"
  tags {
    Name           = "sunil_nat"
    Owner          = "sunil.surendran"
    ExpirationDate = "2018-06-30"
    Project        = "Learning"
    Environment    = "Testing"
  }
}

resource "aws_elb" "sunil_elb" {
  name            = "sunil-elb"
  security_groups = ["${aws_security_group.sunil_elb_sg.id}"]
  subnets = ["${split(",", var.create_vpc ==1 ? join(",", aws_subnet.public.*.id) : join(",", var.subnet_pub))}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }
}

# AUTO SCALING GROUP CONFIGURATION
resource "aws_autoscaling_group" "webserver_group" {
  max_size = 4
  min_size = 2
  vpc_zone_identifier  = ["${split(",", var.create_vpc ==1 ? join(",", aws_subnet.private.*.id) : join(",", var.subnet_pri))}"]
  load_balancers       = ["${aws_elb.sunil_elb.id}"]
  launch_configuration = "${aws_launch_configuration.sunil_launch_asg.name}"
  tags = [
    {
      key                 = "Name"
      value               = "sunil_asg_intance"
      propagate_at_launch = true
    },
    {
      key                 = "Owner"
      value               = "sunil.surendran"
      propagate_at_launch = true
    },
    {
      key                 = "ExpirationDate"
      value               = "2018-06-30"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "Learning"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "Testing"
      propagate_at_launch = true
    },
  ]
}

resource "aws_launch_configuration" "sunil_launch_asg" {
  name            = "sunil_launch_asg"
  image_id        = "${var.webserver_ami}"
  instance_type   = "t2.micro"
  key_name        = "${var.keyname}"
  security_groups = ["${aws_security_group.webserver_security.id}"]
  user_data       = "${file("userdata.sh")}"
}

# ROUTE 53 CONFIGURATION
resource "aws_route53_zone" "sunil_domain" {
  name = "${var.domain_name}"
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.sunil_domain.zone_id}"
  name    = "${var.domain_name}"
  type    = "A"

  alias {
    name                   = "${aws_elb.sunil_elb.dns_name}"
    zone_id                = "${aws_elb.sunil_elb.zone_id}"
    evaluate_target_health = true
  }
}
