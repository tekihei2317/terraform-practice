provider "aws" {
  region = "ap-northeast-1"
}

locals {
  ec2_instance_type = "t3.micro"
}

module "web_server" {
  source = "./modules/http_server"
  instance_type = local.ec2_instance_type
}

output "public_dns" {
  value = module.web_server.public_dns
}