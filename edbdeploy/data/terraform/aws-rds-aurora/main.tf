module "vpc" {
  source = "./environments/vpc"

  vpc_cidr_block = var.vpc_cidr_block
  vpc_tag        = var.vpc_tag
}

module "network" {
  source = "./environments/network"

  # Need at least 2 for AWS RDS.
  #network_count      = 2 + var.pooler_server["count"] > var.hammerdb_server["count"] ? var.pooler_server["count"] : var.hammerdb_server["count"]
  network_count      = 2
  vpc_id             = module.vpc.vpc_id
  public_subnet_tag  = var.public_subnet_tag

  depends_on = [module.vpc]
}

module "routes" {
  source = "./environments/routes"

  pem_count          = var.pem_server["count"]
  hammerdb_count     = var.hammerdb_server["count"]
  barman_count       = var.barman_server["count"]
  pooler_count       = var.pooler_server["count"]
  vpc_id             = module.vpc.vpc_id
  project_tag        = var.project_tag
  public_cidrblock   = var.public_cidrblock

  depends_on = [module.network]
}

module "security" {
  source = "./environments/security"

  vpc_id           = module.vpc.vpc_id
  public_cidrblock = var.public_cidrblock
  project_tag      = var.project_tag

  depends_on = [module.routes]
}

module "aws" {
  # The source module used for creating EC2 systems.
  source = "./environments/aws"

  aws_ami_id                          = var.aws_ami_id
  vpc_id                              = module.vpc.vpc_id
  pem_server                          = var.pem_server
  hammerdb_server                     = var.hammerdb_server
  barman_server                       = var.barman_server
  pooler_server                       = var.pooler_server
  replication_type                    = var.replication_type
  cluster_name                        = var.cluster_name
  ansible_inventory_yaml_filename     = var.ansible_inventory_yaml_filename
  add_hosts_filename                  = var.add_hosts_filename
  custom_security_group_id            = module.security.aws_security_group_id
  ssh_pub_key                         = var.ssh_pub_key
  ssh_priv_key                        = var.ssh_priv_key
  ssh_user                            = var.ssh_user
  created_by                          = var.created_by
  barman                              = var.barman
  pooler_type                         = var.pooler_type
  pooler_local                        = var.pooler_local
  hammerdb                            = var.hammerdb
  public_cidrblock                    = var.public_cidrblock
  project_tag                         = var.project_tag
  rds_security_group_id               = module.security.aws_security_group_id
  postgres_server                     = var.postgres_server
  pg_version                          = var.pg_version

  depends_on = [module.routes]
}
