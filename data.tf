data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

data "aws_ssm_parameter" "root_password" {
  name = "clean-me-root"
}

data "aws_route53_zone" "zone_syzygy_ai" {
  name         = "syzygy-ai.com."
  private_zone = false
}

data "aws_route53_zone" "zone_syzygy_ai_gmbh_de" {
  name         = "syzygy-ai-gmbh.de."
  private_zone = false
}

data "aws_ssm_parameter" "github_runner_token" {
  name = "github_runner_token"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "vault_generic_secret" "slack_api_url" {
  path = format("clean-me/alertmanager")
}

data "aws_eks_cluster" "cluster_e2e" {
  name = module.eks-e2e.cluster_id
}

data "aws_eks_cluster_auth" "cluster_e2e" {
  name = module.eks-e2e.cluster_id
}

data "aws_eks_cluster" "cluster_staging" {
  name = module.eks-staging.cluster_id
}

data "aws_eks_cluster_auth" "cluster_staging" {
  name = module.eks-staging.cluster_id
}

data "aws_iam_policy_document" "this" {
  statement {
    sid     = "GrantK8sSAAccessToAWS"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks-e2e.oidc_provider_arn]
    }
    effect = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks-e2e.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks-e2e.cluster_oidc_issuer_url, "https://", "")}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "this-staging" {
  statement {
    sid     = "GrantK8sSAAccessToAWS"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks-e2e.oidc_provider_arn]
    }
    effect = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks-e2e.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks-e2e.cluster_oidc_issuer_url, "https://", "")}:aud"
      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}
