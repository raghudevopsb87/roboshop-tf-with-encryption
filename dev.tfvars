vpc_cidr_block = "10.0.0.0/22"
env = "dev"
public_subnet = "10.0.0.0/26"
private_subnets = ["10.0.3.0/24", "10.0.2.0/24"]
lb_subnets = ["10.0.0.128/25", "10.0.1.0/25"]
availability_zone_names = ["us-east-1a", "us-east-1b"]
default_vpc_id = "vpc-0f995da5da96d9248"
default_vpc_cidr = "172.31.0.0/16"
default_vpc_rt = "rtb-0e3824c9d7ee324c4"
components = {
  mongodb = {
    instance_type = "t3.small"
    port          = "27017"
    allow_cidr    = ["10.0.3.0/24", "10.0.2.0/24"]
  }
  mysql = {
    instance_type = "t3.small"
    port          = "3306"
    allow_cidr    = ["10.0.3.0/24", "10.0.2.0/24"]
  }
  rabbitmq = {
    instance_type = "t3.small"
    port          = "5672"
    allow_cidr    = ["10.0.3.0/24", "10.0.2.0/24"]
  }
  redis = {
    instance_type = "t3.small"
    port          = "6379"
    allow_cidr    = ["10.0.3.0/24", "10.0.2.0/24"]
  }
}

ami = "ami-045a533d19c34eeb6"
zone_id = "Z057881017RC0RRKVUX8E"
bastion_ips = ["172.31.72.54/32"]
kms = "arn:aws:kms:us-east-1:739561048503:key/ba2caf22-4122-4af7-ab12-e8b52f5d611d"

