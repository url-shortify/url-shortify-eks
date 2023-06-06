output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "vpc_private_subnets_cidr_blocks" {
  value = module.vpc.private_subnets_cidr_blocks
}

output "eks_cluster_name" {
  value = var.eks_cluster_name
}

output "eks_cluster_version" {
  value = module.eks.cluster_version
}
