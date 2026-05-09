/*resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}
*/

resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_security_group" "ec2_sg" {
  name = "ec2_sg"
  vpc_id = var.vpc_id
  
  ingress {
    description = "Restrict EC2 ACCESS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app" {
  name               = "secure-app-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]

  subnets = [
  var.public_subnet_id,
  var.public_subnet2_id
]

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "app" {
  name     = "app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
    port = "80"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.this.id
  port             = 80
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

/*
resource "aws_instance" "this" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.ec2_sg.name]

  tags = {
    Name = var.instance_name
  }
}
*/

resource "aws_instance" "this" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  user_data_replace_on_change = true

  #subnet_id = var.private_subnet_id
  subnet_id = var.public_subnet_id
  associate_public_ip_address = true


  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.profile.name

  #associate_public_ip_address = false

  user_data = <<-EOF
#!/bin/bash

# Update packages
apt update -y

# Install AWS CLI
apt install awscli -y

# Install Docker
snap install docker

# Wait for Docker daemon
sleep 20

# Start Docker manually
systemctl start snap.docker.dockerd

# Extra wait
sleep 10

# Login to ECR
aws ecr get-login-password --region us-east-1 \
| docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}

# Pull image
docker pull ${aws_ecr_repository.app.repository_url}:latest

# Run container
docker run -d -p 80:80 ${aws_ecr_repository.app.repository_url}:latest
EOF

  tags = {
    Name = var.instance_name
  }
}


/*resource "aws_instance" "this" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = var.private_subnet_id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  iam_instance_profile = aws_iam_instance_profile.profile.name

  associate_public_ip_address = false

  tags = {
    Name = var.instance_name
  }

user_data = <<-EOF
#!/bin/bash
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
EOF

}*/

resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_instance_profile" "profile" {
  name = "ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ecr_repository" "app" {
  name = "my-secure-app"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}