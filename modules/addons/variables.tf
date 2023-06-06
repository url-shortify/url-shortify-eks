variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}

variable "route53_zone" {
  description = "Route53 zone name where to create DNS records"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to resources"
  type        = map(string)
}
