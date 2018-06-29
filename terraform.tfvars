#create_vpc = 1
region = "us-west-2"
list_az = [ "us-west-2a", "us-west-2b" ]

# NEW VPC CIDR
#cidr = "172.16.0.0/16"
pub_cidr = [ "10.0.1.0/24", "10.0.2.0/24"]
priv_cidr = [ "10.0.3.0/24", "10.0.4.0/24"]
secure_ip = "61.12.88.78/32"
subnet_pub = [ "subnet-ea3b4893", "subnet-bea03df5" ]
subnet_pri = [ "subnet-4b3e4d32", "subnet-7da73a36" ]

# EXISTING VPC CIDR
subnet_pub = [ "subnet-ea3b4893", "subnet-bea03df5" ]
subnet_pri = [ "subnet-4b3e4d32", "subnet-7da73a36" ]
