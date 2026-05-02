resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = { Name = "secure-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

# Elastic IP for NAT
#resource "aws_eip" "nat" {}

/*resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}
*/
# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

/*resource "aws_route" "private_outbound" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
*/
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# =========================
# VPC ENDPOINT SECURITY GROUP
# =========================
resource "aws_security_group" "endpoint_sg" {
  name   = "endpoint_sg"
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# =========================
# SSM INTERFACE ENDPOINTS
# =========================
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.endpoint_sg.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.endpoint_sg.id]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.endpoint_sg.id]
}

# =========================
# S3 GATEWAY ENDPOINT
# =========================
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]
}