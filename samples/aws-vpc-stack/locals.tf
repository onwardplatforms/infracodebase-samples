locals {
  name_prefix = "demo-${var.demo_id}"

  # Calculate subnet CIDRs from VPC CIDR
  # Public subnets: /24 blocks starting at .0 and .1
  # Private subnets: /24 blocks starting at .10 and .11
  vpc_cidr_prefix = regex("^(\\d+\\.\\d+)\\.", var.vpc_cidr)[0]

  public_subnet_cidrs = [
    "${local.vpc_cidr_prefix}.0.0/24",
    "${local.vpc_cidr_prefix}.1.0/24",
  ]

  private_subnet_cidrs = [
    "${local.vpc_cidr_prefix}.10.0/24",
    "${local.vpc_cidr_prefix}.11.0/24",
  ]

  common_tags = {
    infracodebase_demo = var.demo_id
  }
}
