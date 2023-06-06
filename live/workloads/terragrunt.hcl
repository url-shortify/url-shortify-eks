terraform {
  source = "../..//modules/workloads"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "base" {
  config_path = "../base"
}

inputs = {
  vpc_id                          = dependency.base.outputs.vpc_id
  vpc_database_subnet_group_name  = dependency.base.outputs.vpc_database_subnet_group_name
  vpc_private_subnets_cidr_blocks = dependency.base.outputs.vpc_private_subnets_cidr_blocks
  eks_cluster_name                = dependency.base.outputs.eks_cluster_name
  route53_zone                    = include.root.locals.global_vars.route53_zone
  tags                            = include.root.locals.tags
}
