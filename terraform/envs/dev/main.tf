module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr             = var.vpc_cidr
  region               = var.region
  availability_zones   = var.availability_zones
  vpc_name             = var.vpc_name
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
}

# DNS Module
module "dns" {
  source = "../../modules/dns"

  domain_name       = var.domain_name
  vpc_id            = module.vpc.vpc_id
  private_zone_name = var.private_zone_name
}

# Security Module
module "security" {
  source = "../../modules/security"

  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
}

# Certificate Module
module "certificate" {
  source = "../../modules/certificate"

  domain_name    = var.domain_name
  public_zone_id = module.dns.public_zone_id
  nomad_domain   = "nomad.${var.domain_name}"
  api_domain     = "api.${var.domain_name}"
}


# Load Balancer Module
module "load_balancer" {
  source = "../../modules/load_balancer"

  vpc_id            = module.vpc.vpc_id
  public_subnets    = module.vpc.public_subnets
  security_group_id = module.security.alb_sg_id
  certificate_arn   = module.certificate.certificate_arn
  nomad_domain      = "nomad.${var.domain_name}"
  public_zone_id    = module.dns.public_zone_id
}

/*
# OIDC Provider Module
module "oidc_provider" {
  source = "../../modules/oidc_provider"

  nomad_url     = "https://nomad.${var.domain_name}"
  api_url       = "https://api.${var.domain_name}"
  provider_name = "${var.cluster_name}-nomad-provider"
}
*/


# API Gateway Module
module "api_gateway" {
  source = "../../modules/api_gateway"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  certificate_arn = module.certificate.certificate_arn
  nomad_alb_dns   = module.load_balancer.alb_dns_name
  nomad_domain    = "nomad.${var.domain_name}"
  api_domain      = "api.${var.domain_name}"
  public_zone_id  = module.dns.public_zone_id
  waf_enabled     = var.waf_enabled
  nomad_alb_listener_arn = module.load_balancer.alb_listener_arn
}



# Nomad Cluster Module
module "nomad_cluster" {
  source = "../../modules/nomad_cluster"

  vpc_id               = module.vpc.vpc_id
  private_subnets      = module.vpc.private_subnets
  public_subnets       = module.vpc.public_subnets
  nomad_server_sg_id   = module.security.nomad_server_sg_id
  nomad_client_sg_id   = module.security.nomad_client_sg_id
  cluster_name         = var.cluster_name
  server_instance_type = var.server_instance_type
  client_instance_type = var.client_instance_type
  server_count         = var.server_count
  client_desired_size  = var.client_desired_size
  alb_target_group_arn = module.load_balancer.target_group_arn
  domain_name          = var.domain_name
  api_url              = "https://api.${var.domain_name}"
  region               = var.region
  private_zone_id      = module.dns.private_zone_id # Add this line
  key_name             = var.key_name
}


module "endpoint_ssm" {
  source             = "../../modules/vpc-interface-endpoint"
  vpc_id             = module.vpc.vpc_id
  region             = var.region
  service            = "ssm"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.security.endpoint_sg_id]
}

module "endpoint_ec2messages" {
  source             = "../../modules/vpc-interface-endpoint"
  vpc_id             = module.vpc.vpc_id
  region             = var.region
  service            = "ec2messages"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.security.endpoint_sg_id]
}

module "endpoint_ssmmessages" {
  source             = "../../modules/vpc-interface-endpoint"
  vpc_id             = module.vpc.vpc_id
  region             = var.region
  service            = "ssmmessages"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.security.endpoint_sg_id]
}

module "endpoint_kms" {
  source             = "../../modules/vpc-interface-endpoint"
  vpc_id             = module.vpc.vpc_id
  region             = var.region
  service            = "kms"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.security.endpoint_sg_id]
}

module "endpoint_logs" {
  source             = "../../modules/vpc-interface-endpoint"
  vpc_id             = module.vpc.vpc_id
  region             = var.region
  service            = "logs"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.security.endpoint_sg_id]
}

module "sts" {
  source             = "../../modules/vpc-interface-endpoint"
  vpc_id             = module.vpc.vpc_id
  region             = var.region
  service            = "sts"
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [module.security.endpoint_sg_id]
}

/*
module "endpoint_s3" {
  source          = "../../modules/vpc-gateway-endpoint"
  vpc_id          = module.vpc.vpc_id
  region          = var.region
  service         = "s3"
  route_table_ids = module.vpc.private_route_table_id
}*/

/*
module "windows_bastion" {
  source = "../../modules/windows_bastion"
  
  cluster_name          = var.cluster_name
  vpc_id                = module.vpc.vpc_id
  public_subnets        = module.vpc.public_subnets
  key_name              = var.key_name
  my_ip_address         = "YOUR_IP_ADDRESS"  # Replace with your actual IP (e.g., "203.0.113.1")
  bastion_instance_type = "t3.large"         # Adjust as needed
  create_dns_record     = true               # Set to true if you want a DNS record
  public_zone_id        = module.dns.public_zone_id  # If create_dns_record is true#
  domain_name           = var.domain_name
}*/
