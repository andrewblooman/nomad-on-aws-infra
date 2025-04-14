# terraform.tfvars - Sample values for your Nomad cluster

region               = "eu-west-1"
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
vpc_name             = "nomad-vpc"
public_subnet_count  = 3
private_subnet_count = 3
domain_name          = "nomadsilo.com"
private_zone_name    = "internal.nomadsilo.com"
cluster_name         = "nomad-cluster"
server_instance_type = "t3.medium"
client_instance_type = "t3.large"
server_count         = 3
client_min_size      = 3
client_max_size      = 10
client_desired_size  = 3
waf_enabled          = true
key_name             = "Nomad-Keypair" # Replace with your actual key pair name