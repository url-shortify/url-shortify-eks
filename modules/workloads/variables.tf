variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "vpc_database_subnet_group_name" {
  description = "Name of database subnet group."
  type        = string
}

variable "vpc_private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets."
  type        = list(string)
}

variable "route53_zone" {
  description = "Hosted Zone name where to create DNS records"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to resources"
  type        = map(string)
}
