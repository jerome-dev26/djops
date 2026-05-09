variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  default     = "dev-ec2"
}

variable "domain_name" {
  default = "autodefendops.com"
}
#variable "public_key_path" {
#  description = "Path to SSH public key"
#}

#variable "public_key" {}

/*resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}*/