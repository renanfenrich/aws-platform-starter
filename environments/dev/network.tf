module "network" {
  source = "../../modules/network"

  name_prefix                 = local.name_prefix
  aws_region                  = var.aws_region
  vpc_cidr                    = var.vpc_cidr
  azs                         = local.azs
  public_subnet_cidrs         = var.public_subnet_cidrs
  private_subnet_cidrs        = var.private_subnet_cidrs
  single_nat_gateway          = var.single_nat_gateway
  enable_gateway_endpoints    = var.enable_gateway_endpoints
  enable_interface_endpoints  = var.enable_interface_endpoints
  enable_flow_logs            = var.enable_flow_logs
  flow_logs_retention_in_days = var.flow_logs_retention_in_days
  tags                        = local.tags
}
