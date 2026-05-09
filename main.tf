module "vpc" {
  source = "./modules/vpc"
  domain_name = var.domain_name

}

module "ec2" {
  source = "./modules/ec2"

  instance_name     = var.instance_name
  vpc_id            = module.vpc.vpc_id

  public_subnet_id  = module.vpc.public_subnet_id
  public_subnet2_id = module.vpc.public_subnet2_id

  private_subnet_id = module.vpc.private_subnet_id

  domain_name       = var.domain_name
  zone_id           = module.vpc.zone_id
}