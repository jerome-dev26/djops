variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  default     = "dev-ec2"
}

variable "public_key_path" {
  description = "Path to SSH public key"
}