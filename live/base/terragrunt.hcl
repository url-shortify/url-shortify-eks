terraform {
  source = "../..//modules/base"
}

include "root" {
  path   = find_in_parent_folders()
  expose = true
}

inputs = {
  eks_cluster_name = include.root.locals.project
  tags             = include.root.locals.tags
}
