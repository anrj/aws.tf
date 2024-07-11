provider "aws" {
  profile = "default"
  region  = "eu-central-1"
}

# VPC
resource "aws_vpc" "LAB-1" {
  cidr_block = "12.0.0.0/16"
  tags = {
    Project = ""
    Name    = "LAB-1"
  }
}

# Public subnet 1a
resource "aws_subnet" "public-1a" {
  vpc_id                  = aws_vpc.LAB-1.id
  cidr_block              = "12.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1a"
  }
}

# Public subnet 1b
resource "aws_subnet" "public-1b" {
  vpc_id                  = aws_vpc.LAB-1.id
  cidr_block              = "12.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1b"
  }
}

# Private subnet 1a
resource "aws_subnet" "private-1a" {
  vpc_id            = aws_vpc.LAB-1.id
  cidr_block        = "12.0.3.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "private-1a"
  }
}

# Private subnet 1a
resource "aws_subnet" "private-1b" {
  vpc_id            = aws_vpc.LAB-1.id
  cidr_block        = "12.0.4.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "private-1b"
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.LAB-1.id
  depends_on = [aws_vpc.LAB-1]
  tags = {
    Name = "igw"
  }
}

# Elastic ip
resource "aws_eip" "nat-eip" {
  depends_on = [aws_internet_gateway.igw]
}

# NAT gateway
resource "aws_nat_gateway" "nat-gw" {
  depends_on    = [aws_eip.nat-eip]
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-1a.id

  tags = {
    Name = "nat-gw"
  }
}

# Route table for public
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.LAB-1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rt"
  }
}
# Route table association of public subnet1
resource "aws_route_table_association" "route-public-1a" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-1a.id
}
# Route table association of public subnet2
resource "aws_route_table_association" "route-public-1b" {
  route_table_id = aws_route_table.public-rt.id
  subnet_id      = aws_subnet.public-1b.id
}

# Route table for private
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.LAB-1.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
  tags = {
    Name = "private-rt"
  }
}

# Route table association of private subnet1
resource "aws_route_table_association" "route-private-1a" {
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-1a.id
}

# Route table association of private subnet2
resource "aws_route_table_association" "route-private-1b" {
  route_table_id = aws_route_table.private-rt.id
  subnet_id      = aws_subnet.private-1b.id
}

# Security group
resource "aws_security_group" "fireball" {
  name        = "fireball"
  description = "security group to be used"
  vpc_id      = aws_vpc.LAB-1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  depends_on = [aws_vpc.LAB-1]

  tags = {
    Name = "fireball"
  }
}

# Instances

# Import your key
#resource "aws_key_pair" "homework" {
#  key_name   = "homework"
#  public_key = ""
#}

resource "aws_instance" "instance-1a" {
  ami                    = "ami-0e872aee57663ae2d"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private-1a.id
  vpc_security_group_ids = [aws_security_group.fireball.id]
  key_name               = "homework"
  user_data              = <<EOF
#!/bin/bash
apt-get update
apt-get install nginx -y
systemctl start nginx
EOF

  tags = {
    Name = "instance-1a"
  }
}

resource "aws_instance" "instance-1b" {
  ami                    = "ami-0e872aee57663ae2d"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private-1b.id
  vpc_security_group_ids = [aws_security_group.fireball.id]
  key_name               = "homework"
  user_data              = <<EOF
#!/bin/bash
apt-get update
apt-get install nginx -y
systemctl start nginx
EOF

  tags = {
    Name = "instance-1b"
  }
}


# Target group
resource "aws_lb_target_group" "target-group" {
  name       = "target-group"
  depends_on = [aws_vpc.LAB-1]
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.LAB-1.id
  health_check {
    interval            = 70
    path                = "/"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    protocol            = "HTTP"
    matcher             = "200,202"
  }
}

resource "aws_lb_target_group_attachment" "instance-1a-attachment" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.instance-1a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "instance-1b-attachment" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.instance-1b.id
  port             = 80
}

# Application load balancer
resource "aws_lb" "ALB" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fireball.id]
  subnets            = [aws_subnet.public-1a.id, aws_subnet.public-1b.id]
  tags = {
    name = "ALB"
  }
}

resource "aws_lb_listener" "ALB-listener" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}

# Certificate
resource "aws_acm_certificate" "certificate" {
  domain_name               = "anrj.site"
  subject_alternative_names = ["*.anrj.site"]
  validation_method         = "DNS"

  tags = {
    Name = "anrj.site"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [aws_route53_record.record.fqdn]
}

# Cloudfront distribution
resource "aws_cloudfront_distribution" "anrj_site" {
  enabled = true
  aliases = ["anrj.site"]
  origin {
    domain_name = aws_lb.ALB.dns_name
    origin_id   = aws_lb.ALB.dns_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = aws_lb.ALB.dns_name
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      headers      = []
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.certificate.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}


# Route 53
resource "aws_route53_zone" "hosted_zone" {
  name = "anrj.site"
}

resource "aws_route53_record" "record" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "anrj.site"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.anrj_site.domain_name
    zone_id                = aws_cloudfront_distribution.anrj_site.hosted_zone_id
    evaluate_target_health = false
  }
}
