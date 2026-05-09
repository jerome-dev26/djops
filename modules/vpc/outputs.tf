output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "public_subnet2_id" {
  value = aws_subnet.public2.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}