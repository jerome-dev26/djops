module "ec2" {
  source = "./modules/ec2"

  instance_name  = var.instance_name
  public_key = var.public_key
}

module "vpc" {
  source = "./modules/vpc"
}