variable "create_vpc" {
  description = "Should VPC be created? (ENTER 1 for yes; 0 for no)"
}

variable "region" {
 description = "Region to launch the template"
}

variable "list_az" {
	description = "The Availability Zones for the template"
	type = "list"
}



############# NEW ARCHITECTURE CIDR RANGES
variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "0.0.0.0/0"
}   

variable "pub_cidr" {
  description = "CIDR for Public subnet"
	type = "list"
}   

variable "priv_cidr" {
  description = "CIDR for Private subnet"
	type = "list"
}   

##################EXISTING ARCHITECTURE CIDR RANGES ####################
#variable "exist_cidr" {
#  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
#  default     = "0.0.0.0/0"
#}   
#
#variable "exist_pub_cidr" {
#  description = "CIDR for Public subnet"
#	type = "list"
#}   
#
#variable "exist_priv_cidr" {
#  description = "CIDR for Private subnet"
#	type = "list"
#}   


variable "secure_ip" {
  description = "Secure IP to SSH into instances"
  default = "61.12.88.78/32"
}

variable "bastion_ami" {
  description = "AMI used for Bastion Instance"
  default = "ami-e251209a"
}

variable "webserver_ami" {
  description = "AMI used for Bastion Instance"
  default = "ami-28e07e50"
}

variable "nat_ami" {
  description = "AMI used for Bastion Instance"
  default = "ami-0032ea5ae08aa27a2"
}

variable "keyname" {
  description = "KeyName for account"
  default = "suniloregonec2"
}

variable "exist_vpc_id" {
	default = "vpc-50c0d829"
}

variable "subnet_pub" {
	type = "list"
}

variable "subnet_pri" {
	type = "list"
}

variable "private_rt" {
	default = "rtb-192ddc62"
}
