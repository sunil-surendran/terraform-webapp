variable "create_vpc" {
  description = "Should VPC be created?"
  default     = true
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overriden"
  default     = "0.0.0.0/0"
}   

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
