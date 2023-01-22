#############################################################################
# VPC
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
#############################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.region_name}VPC"
  cidr = "10.0.0.0/16"

  azs            = var.availability_zone_names
  public_subnets = ["10.0.0.0/20"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}
