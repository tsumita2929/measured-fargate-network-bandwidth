#############################################################################
# Variables
#############################################################################
variable "region" {
  type = string
  # Tokyo
  default = "ap-northeast-1"
  # Osaka
  # default = "ap-northeast-3"
}

variable "availability_zone_names" {
  type = list(string)
  # Tokyo
  default = ["apne1-az1"]
  # Osaka
  # default = ["apne3-az1"]
}

variable "region_name" {
  type = string
  # Tokyo
  default = "Tokyo"
  # Osaka
  # default = "Osaka"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  description = "Instance type of EC2 to run the test"
  type        = string
  default     = "c6gn.8xlarge"
}

variable "iperf3_container_image_url" {
  description = "iperf3 ECR Public url"
  type        = string
  default     = "public.ecr.aws/ciscoeti/appn/iperf3:2021.07.30-a82e5f2-3"
}