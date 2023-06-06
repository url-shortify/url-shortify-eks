locals {
  global_vars = yamldecode(file("global.yaml"))
  project     = "${local.global_vars.project}-${local.global_vars.project_id}"

  tags = {
    GitRepository      = "github.com/url-shortify/url-shortify-eks"
    Project            = local.project
    ProvisioningSource = "/${get_path_from_repo_root()}"
  }
}

remote_state {
  backend = "s3"

  config = {
    region         = get_env("AWS_REGION", "eu-west-1")
    bucket         = "${local.project}-tfstate"
    key            = "${get_path_from_repo_root()}/terraform.tfstate"
    encrypt        = true
    s3_bucket_tags = local.tags

    dynamodb_table      = "${local.project}-tfstate-locking"
    dynamodb_table_tags = local.tags
  }
}
