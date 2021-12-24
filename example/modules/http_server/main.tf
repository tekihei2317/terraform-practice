variable "instance_type" {}

resource "aws_security_group" "example_ec2" {
  name = "example-ec2"

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

resource "aws_instance" "default" {
  ami           = "ami-0218d08a1f9dac831"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.example_ec2.id]

  tags = {
    Name = "example"
  }

  user_data = file("${path.module}/user_data.sh")
}

output "public_dns" {
  value = aws_instance.default.public_dns
}
