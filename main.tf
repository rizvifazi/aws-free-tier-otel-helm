provider "aws" {
  region = var.region
}

data "aws_availability_zones" "this" {
  state = "available"
}

# ---------------------
# VPC (3 AZs, NAT GW)
# ---------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.this.names, 0, 3)
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

# ---------------------
# EKS Cluster & NodeGroups (module v21.x interface)
# ---------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.12.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access  = true
  endpoint_private_access = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true
  
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    general = {
      instance_types = var.ng_general_instance_types
      desired_size   = var.ng_general_desired
      min_size       = var.ng_general_min
      max_size       = var.ng_general_max
      subnet_ids     = module.vpc.private_subnets
      tags           = { Name = "ng-general" }
    }

    small = {
      instance_types = var.ng_small_instance_types
      desired_size   = var.ng_small_desired
      min_size       = var.ng_small_min
      max_size       = var.ng_small_max
      subnet_ids     = module.vpc.private_subnets
      tags           = { Name = "ng-small" }
    }
  }

  tags = { Name = var.cluster_name }
}

# ---------------------
# Explicit AWS EKS add-ons (no `cluster_addons` in module)
# ---------------------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = module.eks.cluster_name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = module.eks.cluster_name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name   = "coredns"
}

# ---------------------
# Providers wired to EKS (Option A: exec via AWS CLI, Helm v3 syntax)
# ---------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# ---------------------
# Helm: OpenTelemetry Demo
# ---------------------
resource "helm_release" "otel_demo" {
  name             = "my-otel-demo"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-demo"
  namespace        = "opentelemetry-demo"
  create_namespace = true

  # Optional pin
  # version = var.otel_demo_chart_version

  values = [
    file("${path.module}/helm-values/opentelemetry-demo-values.yaml")
  ]

  timeout = 1200
  depends_on = [
    module.eks,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.coredns
  ]
}

# Add a wait time resource
resource "time_sleep" "wait_lb" {
  create_duration = "60s"
  depends_on      = [helm_release.otel_demo]
}

# Grab the LoadBalancer hostname created for the Frontend Proxy
data "kubernetes_service_v1" "frontendproxy" {
  metadata {
    name      = "${helm_release.otel_demo.name}-frontendproxy"
    namespace = helm_release.otel_demo.namespace
  }
  depends_on = [time_sleep.wait_lb]
}

locals {
  frontendproxy_hostname = coalesce(
    # Try the Hostname (Standard for AWS ELB/ALB)
    try(data.kubernetes_service_v1.frontendproxy.status[0].load_balancer[0].ingress[0].hostname, null),
    
    # Try the IP (Standard for Azure/GCP or MetalLB)
    try(data.kubernetes_service_v1.frontendproxy.status[0].load_balancer[0].ingress[0].ip, null),
    
    # Real Fallback: Internal K8s DNS (works even before the LB is ready)
    "frontendproxy.default.svc.cluster.local"
  )
}
