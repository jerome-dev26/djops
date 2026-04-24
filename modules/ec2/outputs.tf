output "public_ip" {
  value = aws_instance.this.public_ip
}
output "iam_instance_profile" {
  value = aws_iam_instance_profile.profile.name
}