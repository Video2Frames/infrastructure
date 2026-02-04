module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name               = "hackathon-vpc"
  cidr               = "10.0.0.0/16"
  azs                = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets     = [for i in range(3) : cidrsubnet("10.0.0.0/16", 8, i)]
  private_subnets    = [for i in range(3, 6) : cidrsubnet("10.0.0.0/16", 8, i)]
  enable_nat_gateway = true
  single_nat_gateway = true
  tags               = var.tags
}
