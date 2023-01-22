#############################################################################
# SSH Key-Pair
#############################################################################
# Key file name
locals {
  key_pair_name    = "AWS-${var.region_name}-iperf3-Server"
  public_key_file  = "./${local.key_pair_name}.pub"
  private_key_file = "./${local.key_pair_name}.pem"
}

# Create private key file
resource "local_file" "private_key_pem" {
  filename = local.private_key_file
  content  = tls_private_key.keygen.private_key_pem

  # Modify permission
  provisioner "local-exec" {
    command = "chmod 400 ${local.private_key_file}"
  }
}

# Create public key file
resource "local_file" "public_key_openssh" {
  filename = local.public_key_file
  content  = tls_private_key.keygen.public_key_openssh

  # Modify permission
  provisioner "local-exec" {
    command = "chmod 400 ${local.public_key_file}"
  }
}

# Create private key
resource "tls_private_key" "keygen" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "key_pair" {
  key_name   = local.key_pair_name
  public_key = tls_private_key.keygen.public_key_openssh
}

#############################################################################
# EC2
# https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/latest
#############################################################################
# Get latest Amazon Linux 2 AMI ID from SSM parameter store
data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-arm64-gp2"
}

# EC2 Instances(Public, Install iperf3 & run iperf3 deamon)
module "ec2_instance_public" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(module.vpc.azs)

  name = "iperf3-server-${each.key}"

  ami                         = data.aws_ssm_parameter.amzn2_ami.value
  instance_type               = var.instance_type
  private_ip                  = "10.0.10.100"
  key_name                    = local.key_pair_name
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.EC2SecurityGroup.id
  ]
  subnet_id = module.vpc.public_subnets[index(module.vpc.azs, each.value)]

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
  user_data = <<USERDATA
#!/bin/bash
  sudo yum update -y && sudo yum install -y iperf3
  sudo iperf3 -s --daemon
USERDATA
}

#############################################################################
# Security Group
#############################################################################
resource "aws_security_group" "EC2SecurityGroup" {
  description = "Allows All Traffic from shared security group"
  name        = "SharedSecurityGroup"
  tags = {
    Name        = "SharedSecurityGroup"
    Terraform   = "true"
    Environment = var.env
  }
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "Allow alll traffic to which SharedSecurityGroup is attached"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }
  egress {
    description = "Allow alll traffic to which SharedSecurityGroup is attached"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }
  egress {
    description = "Allow All HTTPS traffic to internet(Get container image)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}