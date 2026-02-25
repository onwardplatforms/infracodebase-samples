provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      infracodebase_demo = var.demo_id
      project            = "samples-aws-vpc-stack"
      managed_by         = "terraform"
      environment        = "development"
      purpose            = "demo"
    }
  }
}
