# Use the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets in the default VPC (we'll pick the first one)
data "aws_subnets" "default_in_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "ec2" {
  source = "./modules/ec2"

  name             = var.name
  vpc_id           = data.aws_vpc.default.id
  subnet_id        = data.aws_subnets.default_in_vpc.ids[0]
  instance_type    = var.instance_type
  key_name         = var.key_name
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

