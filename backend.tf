terraform {
  backend "s3" {
    bucket         = "jdev-tf-state-bucket-042026"
    key            = "ec2-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}