output "db_cluster_id" {
  value = module.db.cluster_id
}

output "db_cluster_endpoint" {
  value = module.db.cluster_endpoint
}

output "db_cluster_port" {
  value = module.db.cluster_port
}

output "db_cluster_database_name" {
  value = local.database_name
}

output "db_cluster_master_username" {
  value = local.database_name
}

output "db_cluster_master_user_secret" {
  value = module.db.cluster_master_user_secret
}

output "acm_certificate_arn" {
  value = module.acm.acm_certificate_arn
}

output "acm_certificate_status" {
  value = module.acm.acm_certificate_status
}
