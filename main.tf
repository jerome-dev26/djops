module "ec2" {
  source = "./modules/ec2"

  instance_name      = var.instance_name
  private_subnet_id  = module.vpc.private_subnet_id
  vpc_id             = module.vpc.vpc_id
}

module "vpc" {
  source = "./modules/vpc"
}