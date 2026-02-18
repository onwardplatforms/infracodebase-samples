provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      infracodebase_demo = var.demo_id
      project            = "samples-aws-remote-state-bootstrap"
      managed_by         = "terraform"
      environment        = "demo"
    }
  }
}
