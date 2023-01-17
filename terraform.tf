provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = "eu-north-1"
  alias  = "stockholm"
}

provider "kubernetes" {
  alias                  = "e2e"
  host                   = data.aws_eks_cluster.cluster_e2e.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster_e2e.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_e2e.token
}

provider "helm" {
  alias = "e2e"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster_e2e.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster_e2e.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster_e2e.token
  }
}

provider "kubectl" {
  alias                  = "e2e"
  host                   = data.aws_eks_cluster.cluster_e2e.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster_e2e.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_e2e.token
}

provider "kubernetes" {
  alias                  = "staging"
  host                   = data.aws_eks_cluster.cluster_staging.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster_staging.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_staging.token
}

provider "helm" {
  alias = "staging"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster_staging.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster_staging.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster_staging.token
  }
}

provider "kubectl" {
  alias                  = "staging"
  host                   = data.aws_eks_cluster.cluster_staging.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster_staging.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_staging.token
}

# Uncoment it in case of local run
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }
#
# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#   }
# }
#
# provider "kubectl" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

provider "kubernetes" {
  host                   = "https://kubernetes.default.svc"
  cluster_ca_certificate = file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
  token                  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
}

provider "helm" {
  kubernetes {
    host                   = "https://kubernetes.default.svc"
    cluster_ca_certificate = file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
    token                  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
  }
}

provider "kubectl" {
  host                   = "https://kubernetes.default.svc"
  cluster_ca_certificate = file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
  token                  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }

  backend "s3" {
    bucket = "mm-clean-terraform-state"
    key    = "s3.tfstate"
    region = "eu-west-1"
  }
}

provider "vault" {
  address = "https://vault.syzygy-ai.com"
}
