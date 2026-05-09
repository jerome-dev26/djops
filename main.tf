resource "aws_route53_zone" "main" {
  name = "autodefendops.com"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "autodefendops.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

module "ec2" {
  source = "./modules/ec2"

  instance_name      = var.instance_name
  private_subnet_id  = module.vpc.private_subnet_id
  public_subnet_id = module.vpc.public_subnet_id
  public_subnet2_id = module.vpc.public_subnet2_id
  vpc_id             = module.vpc.vpc_id
  certificate_arn = aws_acm_certificate.cert.arn
  
}

module "vpc" {
  source = "./modules/vpc"
}