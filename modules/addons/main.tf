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

resource "random_password" "argocd_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "bcrypt_hash" "argocd_admin_password" {
  cleartext = random_password.argocd_admin_password.result
}

# tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "argocd_admin_password" {
  name                    = "${var.eks_cluster_name}/argocd/admin_password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "argocd_admin_password" {
  secret_id     = aws_secretsmanager_secret.argocd_admin_password.id
  secret_string = random_password.argocd_admin_password.result
}

data "aws_iam_policy_document" "aws_load_balancer_controller" {
  statement {
    sid    = "AllowGetCertificatesOverride"
    effect = "Allow"

    resources = [
      "*"
    ]

    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates"
    ]
  }
}

module "eks_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 0.2"

  cluster_name      = var.eks_cluster_name
  cluster_endpoint  = data.aws_eks_cluster.this.endpoint
  cluster_version   = data.aws_eks_cluster.this.version
  oidc_provider_arn = data.aws_iam_openid_connect_provider.this.arn

  eks_addons = {
    coredns = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }
  }

  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true
  enable_aws_load_balancer_controller          = true
  enable_external_dns                          = true
  enable_argocd                                = true

  secrets_store_csi_driver = {
    chart_version = "1.3.3"

    set = [
      {
        name  = "enableSecretRotation"
        value = "true"
      },
      {
        name  = "syncSecret.enabled"
        value = "true"
      }
    ]
  }

  secrets_store_csi_driver_provider_aws = {
    chart_version = "0.3.2"
  }

  aws_load_balancer_controller = {
    chart_version           = "1.5.3"
    source_policy_documents = [data.aws_iam_policy_document.aws_load_balancer_controller.json]
  }

  external_dns = {
    chart_version = "1.12.2"
  }

  external_dns_route53_zone_arns = [data.aws_route53_zone.this.arn]

  argocd = {
    chart_version = "5.34.6"

    set = [
      {
        name  = "configs.cm.application.resourceTrackingMethod"
        value = "annotation+label"
      }
    ]

    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt_hash.argocd_admin_password.id
      }
    ]
  }

  helm_releases = {
    reloader = {
      description      = "A Helm chart for k8s stakater/reloader adapter"
      namespace        = "reloader"
      create_namespace = true
      chart            = "reloader"
      chart_version    = "1.0.25"
      repository       = "https://stakater.github.io/stakater-charts"
    }
  }
}
