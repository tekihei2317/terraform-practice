provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/21"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "tf01" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = { Name = "tf01-public-subnet" }
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = { Name = "tf01-gateway" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = { Name = "tf01-route-table" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "example" {
  name   = "tf01-security-group"
  vpc_id = aws_vpc.example.id

  tags = { Name = "tf01-security-group" }
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

resource "aws_instance" "example" {
  ami                    = "ami-0218d08a1f9dac831"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.example.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_for_ssm.name

  user_data = <<EOF
    #! /bin/bash
    yum install -y httpd
    systemctl start httpd.service
  EOF

  tags = { Name = "tf01-instance" }
}

// IAMロール

module "ec2_for_ssm_role" {
  source = "./modules/iam_role"
  name = "ec2-for-ssm"
  identifier = "ec2.amazonaws.com"
  policy = data.aws_iam_policy_document.ec2_for_ssm.json
}

data "aws_iam_policy_document" "ec2_for_ssm" {
  source_json = data.aws_iam_policy.ec2_for_ssm.policy

  statement {
    effect = "Allow"
    resources = ["*"]

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "kms:Decrypt",
    ]
  }
}

data "aws_iam_policy" "ec2_for_ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_for_ssm" {
  name = "ec2-for-ssm"
  role = module.ec2_for_ssm_role.iam_role_name
}
