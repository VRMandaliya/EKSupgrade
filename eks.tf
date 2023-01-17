module "eks" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "18.24.1"
  cluster_name                    = local.name
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_endpoint_public_access_cidrs = ["37.120.31.123/32", "34.243.185.49/32", "54.75.4.248/32", "86.56.76.214/32", "158.181.79.22/32", "5.164.208.50/32", "5.3.213.106/32", "91.77.164.70/32", "212.91.244.2/32"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size                    = 50
    instance_types               = ["t2.micro"]
    vpc_security_group_ids       = [module.rds_backend_security_group.security_group_id, "sg-05a5687d6d6873ea3"]
    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }

  eks_managed_node_groups = {
    blue = {
      create_launch_template = false
      launch_template_name   = ""
      min_size               = 1
      max_size               = 2
      desired_size           = 1

      instance_types = ["t3.medium"]
      labels = {
        Product = "clean-me"
      }

      tags = {
        Name = "clean-me"
      }
    }
    green = {
      create_launch_template = false
      launch_template_name   = ""
      min_size               = 1
      max_size               = 2
      desired_size           = 1

      instance_types = ["t3.medium"]
      labels = {
        Product = "clean-me"
      }
    }
    heavy = {
      create_launch_template = false
      launch_template_name   = ""
      min_size               = 1
      max_size               = 2
      desired_size           = 1

      instance_types = ["t3.large"]
      labels = {
        Product = "clean-me-search"
      }
    }
  }
}

module "cert_manager" {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-cert-manager.git"

  enabled = true

  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
}

module "github_runner" {
  source = "../modules/github_runner"

  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn

  github_token               = data.aws_ssm_parameter.github_runner_token.value
  github_app_private_key     = ""
  github_app_app_id          = ""
  github_app_installation_id = ""


  github_autoscaler_repositories = [
    {
      name         = "nn-team/cleaning_backend"
      min_replicas = 1
      max_replicas = 2
      label        = "ga"
    },
    {
      name         = "nn-team/cleaning_search_backend"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
    {
      name         = "nn-team/cleaner_paradise_poc"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
    {
      name         = "nn-team/smart_mirror_android_client"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
    {
      name         = "nn-team/smart_mirror_ios_client"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
    {
      name         = "nn-team/demo"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
    {
      name         = "nn-team/monkey_mirror"
      min_replicas = 0
      max_replicas = 2
      label        = "ga"
    },
    {
      name         = "nn-team/cleaning_ssn_backend"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
    {
      name         = "nn-team/landing"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
    {
      name         = "nn-team/auto_turbo_clean"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
    {
      name         = "nn-team/cleaning_search_core"
      min_replicas = 0
      max_replicas = 1
      label        = "ga"
    },
  ]
  policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]

  settings = {
    syncPeriod = "1m"
  }

  depends_on = [module.cert_manager]
}

resource "kubernetes_cluster_role_binding_v1" "github-actions-runner-controller" {
  metadata {
    name = "github-actions-runner-controller"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "admin"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "github-actions-runner-controller"
    namespace = "actions-runner-system"
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

module "db-dump-s3-sa" {
  source                      = "tinfoilcipher/eks-service-account-with-oidc-iam-role/aws"
  version                     = "0.1.4"
  service_account_name        = "db-dump-s3"
  iam_policy_arns             = [aws_iam_policy.clean_me_dump_s3.arn, "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"]
  kubernetes_namespace        = "default"
  enabled_sts_services        = ["s3"]
  openid_connect_provider_arn = module.eks.oidc_provider_arn
  openid_connect_provider_url = module.eks.cluster_oidc_issuer_url
}

resource "kubectl_manifest" "db-dump-s3-cron-job" {
  yaml_body = file("../../k8s/cron-jobs/db-dump-s3.yml")

  depends_on = [module.db-dump-s3-sa]
}

module "eks-external-dns" {
  source                           = "DNXLabs/eks-external-dns/aws"
  version                          = "0.1.4"
  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
}

resource "helm_release" "kibana" {
  name       = "kibana"
  repository = "elastic"
  chart      = "kibana"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  values = [
    "${file("scripts/values-elk.yml")}"
  ]
}

resource "helm_release" "filebeat" {
  name       = "filebeat"
  repository = "elastic"
  chart      = "filebeat"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  values = [
    "${file("scripts/values-elk.yml")}"
  ]
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "elastic"
  chart      = "elasticsearch"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  values = [
    "${file("scripts/values-elk.yml")}"
  ]
}

module "aws-metricbeat-sa" {
  source                      = "tinfoilcipher/eks-service-account-with-oidc-iam-role/aws"
  version                     = "0.1.4"
  service_account_name        = "aws-metricbeat"
  iam_policy_arns             = [aws_iam_policy.aws-metricbeat.arn, "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"]
  kubernetes_namespace        = kubernetes_namespace.observability.metadata[0].name
  enabled_sts_services        = []
  openid_connect_provider_arn = module.eks.oidc_provider_arn
  openid_connect_provider_url = module.eks.cluster_oidc_issuer_url
}

resource "kubernetes_cluster_role" "aws-metricbeat-role" {
  metadata {
    name = "aws-metricbeat"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces", "events", "pods", "services"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["replicasets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["statefulsets", "deployments", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes/stats"]
    verbs      = ["get"]
  }
  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }

  depends_on = [module.aws-metricbeat-sa]
}

resource "kubernetes_cluster_role_binding_v1" "aws-metricbeat" {
  metadata {
    name = "aws-metricbeat"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "aws-metricbeat"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "aws-metricbeat"
    namespace = kubernetes_namespace.observability.metadata[0].name
  }

  depends_on = [kubernetes_cluster_role.aws-metricbeat-role]
}

resource "kubernetes_namespace" "observability" {
  metadata {
    name = "observability"
  }
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

module "vault-sa" {
  source                      = "tinfoilcipher/eks-service-account-with-oidc-iam-role/aws"
  version                     = "0.1.4"
  service_account_name        = "vault-sa"
  iam_policy_arns             = [aws_iam_policy.clean_me_vault_s3.arn]
  kubernetes_namespace        = kubernetes_namespace.vault.metadata[0].name
  enabled_sts_services        = []
  openid_connect_provider_arn = module.eks.oidc_provider_arn
  openid_connect_provider_url = module.eks.cluster_oidc_issuer_url

  depends_on = [kubernetes_namespace.vault]
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "hashicorp"
  chart      = "vault"
  namespace  = kubernetes_namespace.vault.metadata[0].name
  values = [
    "${file("scripts/values-vault.yml")}"
  ]

  depends_on = [module.vault-sa]
}

resource "kubectl_manifest" "vault-ingress" {
  override_namespace = kubernetes_namespace.vault.metadata[0].name
  yaml_body          = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault-ingress
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/subnets: subnet-0d36225af104192e0, subnet-0279b423dba585f0a,
      subnet-0b7461569494c4267
    alb.ingress.kubernetes.io/success-codes: "307"
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: ${module.wildcard_com.acm_certificate.arn}
    external-dns.alpha.kubernetes.io/hostname: vault.syzygy-ai.com
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: vault
                port:
                  number: 8200
YAML
}

resource "helm_release" "prometheus-stack" {
  name        = "prometheus"
  repository  = "prometheus-community"
  chart       = "kube-prometheus-stack"
  description = "FIXME TODO dummy string"
  namespace   = kubernetes_namespace.observability.metadata[0].name
  values = [
    "${file("scripts/values-prometheus.yml")}"
  ]
  set {
    name  = "alertmanager.config.global.slack_api_url"
    value = data.vault_generic_secret.slack_api_url.data["slack_api_url"]
  }
}

resource "kubectl_manifest" "prometheus-ingress" {
  override_namespace = kubernetes_namespace.observability.metadata[0].name
  yaml_body          = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/subnets: subnet-0d36225af104192e0, subnet-0279b423dba585f0a,
      subnet-0b7461569494c4267
    alb.ingress.kubernetes.io/success-codes: "302"
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/target-type: ip
    external-dns.alpha.kubernetes.io/hostname: prometheus.syzygy-ai.internal
    external-dns.alpha.kubernetes.io/hostname: alertmanager.syzygy-ai.internal
    external-dns.alpha.kubernetes.io/hostname: grafana.syzygy-ai.internal
    external-dns.alpha.kubernetes.io/hostname: kibana.syzygy-ai.internal
    external-dns.alpha.kubernetes.io/hostname: elk.syzygy-ai.internal
spec:
  rules:
    - host: prometheus.syzygy-ai.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-prometheus
                port:
                  number: 9090
                  rules:
    - host: alertmanager.syzygy-ai.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-alertmanager
                port:
                  number: 9093
    - host: grafana.syzygy-ai.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
    - host: kibana.syzygy-ai.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kibana-kibana
                port:
                  number: 5601
    - host: elk.syzygy-ai.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: elasticsearch-master
                port:
                  number: 9200
YAML
}

resource "helm_release" "prometheus-cloudwatch-exporter" {
  name       = "prometheus-cloudwatch-exporter"
  repository = "prometheus-community"
  chart      = "prometheus-cloudwatch-exporter"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  values = [
    "${file("scripts/values-prometheus-cloudwatch-exporter.yml")}"
  ]
}

module "eks-e2e" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "18.24.1"
  cluster_name                    = "clean-me-e2e"
  cluster_version                 = "1.22"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_endpoint_public_access_cidrs = []

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size                    = 50
    instance_types               = ["t2.micro"]
    vpc_security_group_ids       = [module.rds_backend_security_group.security_group_id, "sg-05a5687d6d6873ea3"]
    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }

  eks_managed_node_groups = {
    e2e = {
      create_launch_template = false
      launch_template_name   = ""
      min_size               = 1
      max_size               = 1
      desired_size           = 1

      instance_types = ["t3.medium"]
      labels = {
        Product = "clean-me-e2e"
      }

      tags = {
        Name = "clean-me-e2e"
      }
    }
  }
}

module "aws-l-b-controller-clen-me" {
  source                      = "tinfoilcipher/eks-service-account-with-oidc-iam-role/aws"
  version                     = "0.1.4"
  service_account_name        = "aws-load-balancer-controller"
  iam_policy_arns             = ["arn:aws:iam::620428644349:policy/AWSLoadBalancerControllerIAMPolicy"]
  kubernetes_namespace        = "kube-system"
  enabled_sts_services        = []
  openid_connect_provider_arn = module.eks.oidc_provider_arn
  openid_connect_provider_url = module.eks.cluster_oidc_issuer_url
  provision_k8s_sa            = false

  depends_on = [helm_release.aws-load-balancer-controller-e2e]
}

module "aws-l-b-controller-e2e" {
  providers = {
    kubernetes = kubernetes.e2e
  }
  source                      = "tinfoilcipher/eks-service-account-with-oidc-iam-role/aws"
  version                     = "0.1.4"
  service_account_name        = "aws-load-balancer-controller-e2e"
  iam_policy_arns             = ["arn:aws:iam::620428644349:policy/AWSLoadBalancerControllerIAMPolicy"]
  kubernetes_namespace        = "kube-system"
  enabled_sts_services        = []
  openid_connect_provider_arn = module.eks-e2e.oidc_provider_arn
  openid_connect_provider_url = module.eks-e2e.cluster_oidc_issuer_url
  provision_k8s_sa            = false

  depends_on = [helm_release.aws-load-balancer-controller-e2e]
}

module "clean-me-e2e-sa-role" {
  providers = {
    kubernetes = kubernetes.e2e
  }
  source                      = "tinfoilcipher/eks-service-account-with-oidc-iam-role/aws"
  version                     = "0.1.4"
  service_account_name        = "clean-me-e2e"
  iam_policy_arns             = [aws_iam_policy.clean_me_e2e_s3.arn]
  kubernetes_namespace        = "clean-me-e2e"
  enabled_sts_services        = []
  openid_connect_provider_arn = module.eks-e2e.oidc_provider_arn
  openid_connect_provider_url = module.eks-e2e.cluster_oidc_issuer_url
}

resource "helm_release" "aws-load-balancer-controller-e2e" {
  provider   = helm.e2e
  name       = "aws-load-balancer-controller-e2e"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  values = [
    "${file("scripts/values-aws-lbc-e2e.yaml")}"
  ]
}

resource "helm_release" "vault-injector-e2e" {
  provider   = helm.e2e
  name       = "vault"
  repository = "hashicorp"
  chart      = "vault"
  namespace  = "kube-system"

  set {
    name  = "injector.externalVaultAddr"
    value = "https://vault.syzygy-ai.com/"
  }
}

resource "helm_release" "kube-state-metrics-e2e" {
  provider   = helm.e2e
  name       = "kube-state-metrics"
  repository = "prometheus-community"
  chart      = "kube-state-metrics"
  namespace  = "kube-system"
}

resource "kubectl_manifest" "clean-me-e2e-ingress" {
  provider           = kubectl.e2e
  override_namespace = "kube-system"
  yaml_body          = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: clena-me-e2e-ingress
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/subnets: subnet-0d36225af104192e0, subnet-0279b423dba585f0a,
      subnet-0b7461569494c4267
    alb.ingress.kubernetes.io/success-codes: "200"
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/target-type: ip
    external-dns.alpha.kubernetes.io/hostname: kube-state-metrics-e2e.syzygy-ai.internal
spec:
  rules:
    - host: kube-state-metrics-e2e.syzygy-ai.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kube-state-metrics
                port:
                  number: 8080
YAML

  depends_on = [helm_release.kube-state-metrics-e2e]
}

module "eks-e2e-external-dns" {
  providers = {
    helm       = helm.e2e
    kubernetes = kubernetes.e2e
  }
  source                           = "DNXLabs/eks-external-dns/aws"
  cluster_name                     = module.eks-e2e.cluster_id
  cluster_identity_oidc_issuer     = module.eks-e2e.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks-e2e.oidc_provider_arn
  helm_chart_version               = "6.5.0"
}

resource "helm_release" "filebeat-e2e" {
  provider   = helm.e2e
  name       = "filebeat"
  repository = "elastic"
  chart      = "filebeat"
  namespace  = "kube-system"
  values = [
    "${file("scripts/values-filebeat-e2e.yml")}"
  ]
}

resource "kubernetes_namespace" "clean-me-e2e" {
  provider = kubernetes.e2e
  metadata {
    name = "clean-me-e2e"
  }
}

resource "kubectl_manifest" "ssm-agent-daemonset" {
  yaml_body = file("scripts/ssm_daemonset.yaml")
}

resource "kubectl_manifest" "ssm-agent-daemonset-e2e" {
  provider           = kubectl.e2e
  override_namespace = "kube-system"
  yaml_body          = file("scripts/ssm_daemonset.yaml")
}

module "eks-staging" {
  source                          = "terraform-aws-modules/eks/aws"
  version                         = "18.24.1"
  cluster_name                    = "clean-me-staging"
  cluster_version                 = "1.21"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  cluster_endpoint_public_access_cidrs = []

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
  }

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size                    = 50
    instance_types               = ["t2.micro"]
    vpc_security_group_ids       = [module.rds_backend_security_group.security_group_id, "sg-05a5687d6d6873ea3"]
    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly", "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  }

  eks_managed_node_groups = {
    staging = {
      create_launch_template = false
      launch_template_name   = ""
      min_size               = 1
      max_size               = 1
      desired_size           = 1

      instance_types = ["t3.medium"]
      labels = {
        Product = "clean-me-staging"
      }

      tags = {
        Name = "clean-me-staging"
      }
    }
  }
}

module "aws-l-b-controller-staging" {
  providers = {
    kubernetes = kubernetes.staging
  }
  source                      = "tinfoilcipher/eks-service-account-with-oidc-iam-role/aws"
  version                     = "0.1.4"
  service_account_name        = "aws-load-balancer-controller-staging"
  iam_policy_arns             = ["arn:aws:iam::620428644349:policy/AWSLoadBalancerControllerIAMPolicy"]
  kubernetes_namespace        = "kube-system"
  enabled_sts_services        = []
  openid_connect_provider_arn = module.eks-staging.oidc_provider_arn
  openid_connect_provider_url = module.eks-staging.cluster_oidc_issuer_url
  provision_k8s_sa            = false

  depends_on = [helm_release.aws-load-balancer-controller-staging]
}

module "clean-me-staging-sa-role" {
  providers = {
    kubernetes = kubernetes.staging
  }
  source                      = "tinfoilcipher/eks-service-account-with-oidc-iam-role/aws"
  version                     = "0.1.4"
  service_account_name        = "clean-me-staging"
  iam_policy_arns             = [aws_iam_policy.clean_me_staging_s3.arn]
  kubernetes_namespace        = "clean-me-staging"
  enabled_sts_services        = []
  openid_connect_provider_arn = module.eks-staging.oidc_provider_arn
  openid_connect_provider_url = module.eks-staging.cluster_oidc_issuer_url
}

resource "helm_release" "aws-load-balancer-controller-staging" {
  provider   = helm.staging
  name       = "aws-lb-controller-staging"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  values = [
    "${file("scripts/values-aws-lbc-staging.yaml")}"
  ]
}

resource "helm_release" "vault-injector-staging" {
  provider   = helm.staging
  name       = "vault"
  repository = "hashicorp"
  chart      = "vault"
  namespace  = "kube-system"

  set {
    name  = "injector.externalVaultAddr"
    value = "https://vault.syzygy-ai.com/"
  }
}

resource "helm_release" "kube-state-metrics-staging" {
  provider   = helm.staging
  name       = "kube-state-metrics"
  repository = "prometheus-community"
  chart      = "kube-state-metrics"
  namespace  = "kube-system"
}

resource "helm_release" "logstash-staging" {
  provider   = helm.staging
  name       = "logstash"
  chart      = "logstash"
  repository = "elastic"
  namespace  = "kube-system"
  values = [
    "${file("scripts/values-logstash-staging.yaml")}"
  ]
}

resource "kubectl_manifest" "clean-me-staging-ingress" {
  provider           = kubectl.staging
  override_namespace = "kube-system"
  yaml_body          = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: clena-me-staging-ingress
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/subnets: subnet-0d36225af104192e0, subnet-0279b423dba585f0a,
      subnet-0b7461569494c4267
    alb.ingress.kubernetes.io/success-codes: "200"
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/target-type: ip
    external-dns.alpha.kubernetes.io/hostname: kube-state-metrics-staging.syzygy-ai.internal
    external-dns.alpha.kubernetes.io/hostname: logstash.syzygy-ai.internal
spec:
  rules:
    - host: kube-state-metrics-staging.syzygy-ai.internal
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kube-state-metrics
                port:
                  number: 8080
    - host: logstash.syzygy-ai.internal
      tcp:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: logstash-logstash
                port:
                  number: 5044
YAML

  depends_on = [helm_release.kube-state-metrics-staging, module.eks-staging-external-dns]
}

module "eks-staging-external-dns" {
  providers = {
    helm       = helm.staging
    kubernetes = kubernetes.staging
  }
  source                           = "DNXLabs/eks-external-dns/aws"
  cluster_name                     = module.eks-staging.cluster_id
  cluster_identity_oidc_issuer     = module.eks-staging.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks-staging.oidc_provider_arn
  helm_chart_version               = "6.5.0"
}

resource "helm_release" "filebeat-staging" {
  provider   = helm.staging
  name       = "filebeat"
  chart      = "filebeat"
  repository = "elastic"
  namespace  = "kube-system"
  values = [
    "${file("scripts/values-filebeat-staging.yml")}"
  ]
}

resource "kubernetes_namespace" "clean-me-staging" {
  provider = kubernetes.staging
  metadata {
    name = "clean-me-staging"
  }
}
