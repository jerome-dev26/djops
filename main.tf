module "ec2" {
  source = "./modules/ec2"

  instance_name  = var.instance_name
  public_key_path = var.public_key_path
}

module "vpc" {
  source = "./modules/vpc"
}