locals {
  application   = "url-shortify"
  database_name = replace(lower(local.application), "/[^a-z0-9_]/", "_")
  domain        = "${local.application}.${var.route53_zone}"
}

data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

data "aws_route53_zone" "this" {
  name = var.route53_zone
}

module "db" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 8.1"

  name           = var.eks_cluster_name
  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = "15.2"

  database_name               = local.database_name
  master_username             = local.database_name
  manage_master_user_password = true

  vpc_id               = var.vpc_id
  db_subnet_group_name = var.vpc_database_subnet_group_name

  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = var.vpc_private_subnets_cidr_blocks
    }
  }

  storage_encrypted   = true
  apply_immediately   = true
  skip_final_snapshot = true
  monitoring_interval = 60

  # https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.how-it-works.html#aurora-serverless-v2.how-it-works.capacity
  serverlessv2_scaling_configuration = {
    min_capacity = 1
    max_capacity = 4
  }

  instance_class = "db.serverless"

  instances = {
    primary = {}
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = local.domain
  zone_id     = data.aws_route53_zone.this.id

  subject_alternative_names = [
    "*.${local.domain}",
  ]
}

data "aws_iam_policy_document" "eks_irsa" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [module.db.cluster_master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_policy" "eks_irsa" {
  name_prefix = "${var.eks_cluster_name}-eks-irsa-"
  description = "IAM policy for EKS Service Account ${local.application}:${local.application}"
  policy      = data.aws_iam_policy_document.eks_irsa.json
}

module "eks_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${var.eks_cluster_name}-eks-irsa-"
  role_description = "IAM role for EKS Service Account ${local.application}:${local.application}"

  role_policy_arns = {
    policy = aws_iam_policy.eks_irsa.arn
  }

  oidc_providers = {
    one = {
      provider_arn               = data.aws_iam_openid_connect_provider.this.arn
      namespace_service_accounts = ["${local.application}:${local.application}"]
    }
  }
}

resource "helm_release" "argo_application" {
  name         = "argo-application"
  namespace    = "argocd"
  force_update = true

  repository = "https://url-shortify.github.io/url-shortify-charts"
  chart      = "argo-application"
  version    = "1.0.0"

  set {
    name  = "name"
    value = local.application
  }

  set {
    name  = "namespace"
    value = local.application
  }

  set {
    name  = "source.repoUrl"
    value = "https://url-shortify.github.io/url-shortify-charts"
  }

  set {
    name  = "source.chart"
    value = "url-shortify"
  }

  set {
    name  = "source.targetRevision"
    value = "1.*"
  }

  set {
    name = "source.helm.values"
    type = "auto"

    value = yamlencode({
      host = local.domain

      database = {
        host     = module.db.cluster_endpoint
        port     = module.db.cluster_port
        database = local.database_name

        credentials = {
          secretArn = module.db.cluster_master_user_secret[0].secret_arn
        }
      }

      serviceAccount = {
        roleArn = module.eks_irsa.iam_role_arn
      }

      tags = [for name, value in var.tags : "${name}=${value}"]
    })
  }
}
