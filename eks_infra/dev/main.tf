data "aws_availability_zones" "available" {}

locals {

  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  tags = {
    environment = var.environment
  }
}

################################################################################
# EKS VPC
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0"

  name = "${var.vpc_name}-${var.environment}"
  cidr = var.vpc_cidr

  azs                     = local.azs
  map_public_ip_on_launch = true
  private_subnets         = var.vpc_private_subnets
  public_subnets          = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway
  single_nat_gateway = var.vpc_single_nat_gateway

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "Type"                            = "private-subnet"
    "karpenter.sh/discovery"          = var.cluster_name
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "Type"                   = "public-subnets"
  }

  tags = local.tags

}
