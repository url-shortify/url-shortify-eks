terraform {
  source = "../..//modules/addons"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "base" {
  config_path = "../base"
}

inputs = {
  eks_cluster_name = dependency.base.outputs.eks_cluster_name
  route53_zone     = include.root.locals.global_vars.route53_zone
  tags             = include.root.locals.tags
}
