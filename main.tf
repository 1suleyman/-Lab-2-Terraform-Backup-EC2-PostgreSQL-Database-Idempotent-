
module "ec2" {
  source = "./modules/ec2"

  name             = var.name
  vpc_id           = module.networking.vpc_id
  subnet_id        = module.networking.public_subnet_ids[0]   # EC2 in public subnet for SSH
  instance_type    = var.instance_type
  key_name         = var.key_name
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

module "networking" {
  source = "./modules/networking"

  name_prefix          = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  tags               = var.tags
}