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

#resource "aws_subnet" "public_2" {
#  availability_zone       = "us-west-2b"
#  cidr_block              = "10.0.2.0/24"
#  map_public_ip_on_launch = true
#  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"
#
#  tags {
#    Name = "sunil-tf-pub-B"
#  }
#}
#
#resource "aws_subnet" "private_1" {
#  availability_zone       = "us-west-2a"
#  cidr_block              = "10.0.3.0/24"
#  map_public_ip_on_launch = false
#  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"
#
#  tags {
#    Name = "sunil-tf-pri-A"
#  }
#}
#
#resource "aws_subnet" "private_2" {
#  availability_zone       = "us-west-2b"
#  cidr_block              = "10.0.4.0/24"
#  map_public_ip_on_launch = false
#  vpc_id                  = "${aws_vpc.sunil-tf-vpc.id}"
#
#  tags {
#    Name = "sunil-tf-pri-B"
#  }
#}
#
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
	count = "${var.create_vpc ? 0 : 1}"
  route_table_id = "${var.private_rt}"
  instance_id    = "${aws_instance.sunil_nat.id}"
	destination_cidr_block = "0.0.0.0/0"
}

# SUBNET-ROUTE TABLE ASSOCIATION

resource "aws_route_table_association" "public_route" {
  count     = "${var.create_vpc==1 ? length(var.list_az) : 0 }"
  subnet_id = "${element(concat(aws_subnet.public.*.id, list("")), count.index)}"

  #subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

#resource "aws_route_table_association" "public_2" {
#  subnet_id      = "${aws_subnet.public_2.id}"
#  route_table_id = "${aws_route_table.public_route_table.id}"
#}

resource "aws_route_table_association" "private_route" {
  count = "${length(var.list_az)}"

  #subnet_id      = "${list(join("", aws_subnet.private.*.id), count.index)}"
  #subnet_id      = "${list(element(anatet.private.*.id, count.index))}"
  subnet_id = "${var.create_vpc==1 ? element(concat(aws_subnet.private.*.id, list("")), count.index) : element(var.subnet_pri, count.index)}"

  route_table_id = "${var.create_vpc==1 ? join("",  aws_route_table.private_route_table.*.id) : var.private_rt}"
}

#resource "aws_route_table_association" "private_2" {
#  subnet_id      = "${aws_subnet.private_2.id}"
#  route_table_id = "${aws_route_table.private_route_table.id}"
#}
#
# SECURITY GROUP CONFIGURATIONS
resource "aws_security_group" "bastion_security" {
  name        = "bastion_security"
  description = "Allow SSH access to bastion"
  vpc_id      = "${var.create_vpc==1 ? join("", aws_vpc.sunil-tf-vpc.*.id) : var.exist_vpc_id}"

  #vpc_id      = "${var.create_vpc==1 ? aws_vpc.sunil-tf-vpc.id : var.exist_vpc_id}"

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

  #vpc_id      = "${var.create_vpc==1 ? aws_vpc.sunil-tf-vpc.id : var.exist_vpc_id}"


  #vpc_id      = "${aws_vpc.sunil-tf-vpc.id}"

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

  #vpc_id      = "${var.create_vpc==1 ? aws_vpc.sunil-tf-vpc.id : var.exist_vpc_id}"


  #vpc_id      = "${aws_vpc.sunil-tf-vpc.id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["${var.secure_ip}"]

    #cidr_blocks = ["${split(",", var.create_vpc ==1 ? join(",", var.cidr) : join(",", var.exist_cidr))}"]
    #cidr_blocks = ["${var.create_vpc==1 ? element(concat(var.cidr, list()), 0) : element(concat(var.exist_cidr, list()), 0)}"]
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

  #vpc_id      = "${aws_vpc.sunil-tf-vpc.id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["${var.cidr}"]

    #cidr_blocks = ["${split(",", var.create_vpc==1 ? join(",", var.cidr) : join(",", var.exist_cidr))}"]
    #cidr_blocks = ["${var.create_vpc==1 ? element(concat(var.cidr, list())) : element(concat(var.exist_cidr, list()))}"]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    cidr_blocks = ["${var.cidr}"]

    #cidr_blocks = ["${split(",", var.create_vpc==1 ? join(",", var.cidr) : join(",", var.exist_cidr))}"]
    #cidr_blocks = ["${var.create_vpc==1 ? element(concat(var.cidr, list()), 0) : element(concat(var.exist_cidr, list()), 0)}"]
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

  #subnet_id                   = "${aws_subnet.public_2.id}"
  associate_public_ip_address = "true"

  tags {
    Name           = "sunil_nat"
    Owner          = "sunil.surendran"
    ExpirationDate = "2018-06-30"
    Project        = "Learning"
    Environment    = "Testing"
  }
}

##
###resource "aws_instance" "sunil_webserver_a" {
###  depends_on = [ "aws_instance.sunil_nat" ]
###  ami = "${var.webserver_ami}"
###  availability_zone = "us-west-2a"
###  instance_type = "t2.micro"
###  key_name = "${var.keyname}"
###  vpc_security_group_ids = [ "${aws_security_group.webserver_security.id}" ]
###  subnet_id = "${aws_subnet.private_1.id}"
###  associate_public_ip_address = "false"
###  tags {
###    Name           = "sunil_webserver_a"
###    Owner          = "sunil.surendran"
###    ExpirationDate = "2018-06-30"
###    Project        = "Learning"
###    Environment    = "Testing"
###  }
###  user_data = "${file("userdata.sh")}"
###}
##
##resource "aws_instance" "sunil_webserver_b" {
##  depends_on = [ "aws_instance.sunil_nat" ]
##  ami = "${var.webserver_ami}"
##  availability_zone = "us-west-2b"
##  instance_type = "t2.micro"
##  key_name = "${var.keyname}"
##  vpc_security_group_ids = [ "${aws_security_group.webserver_security.id}" ]
##  subnet_id = "${aws_subnet.private_2.id}"
##  associate_public_ip_address = "false"
##  tags {
##    Name           = "sunil_webserver_b"
##    Owner          = "sunil.surendran"
##    ExpirationDate = "2018-06-30"
##    Project        = "Learning"
##    Environment    = "Testing"
##  }
##  user_data = "${file("userdata.sh")}"
##}
#
# ELASTIC LOAD BALANCER

resource "aws_elb" "sunil_elb" {
  name            = "sunil-elb"
  security_groups = ["${aws_security_group.sunil_elb_sg.id}"]

  #	subnets         = ["${var.create_vpc==1 ? aws_subnet.public.*.id : var.subnet_pub}"]
  subnets = ["${split(",", var.create_vpc ==1 ? join(",", aws_subnet.public.*.id) : join(",", var.subnet_pub))}"]

  #	availability_zones = ["${var.list_az}"]

  #  instances = [ "${aws_instance.sunil_webserver_a.id}", "${aws_instance.sunil_webserver_b.id}" ]
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

#
# AUTO SCALING GROUP CONFIGURATION

resource "aws_autoscaling_group" "webserver_group" {
  max_size = 4
  min_size = 2

  #  vpc_zone_identifier  = ["${aws_subnet.private.*.id}"]
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
