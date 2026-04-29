variable "instance_name" {}
#variable "public_key" {}
variable "private_subnet_id" {
  description = "Private subnet where EC2 will be deployed"
}

variable "vpc_id" {
  description = "VPC where resources will be created"
}