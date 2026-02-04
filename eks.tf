module "eks" {
  source                                   = "terraform-aws-modules/eks/aws"
  version                                  = "21.3.1"
  name                                     = "hackathon-eks"
  kubernetes_version                       = "1.33"
  endpoint_public_access                   = true
  endpoint_private_access                  = true
  deletion_protection                      = false
  enable_cluster_creator_admin_permissions = true
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = module.vpc.private_subnets
  tags                                     = var.tags

  eks_managed_node_groups = {
    "general-purpose" = {
      desired_size   = 3
      min_size       = 2
      max_size       = 6
      instance_types = ["t3.small"]
      subnets        = module.vpc.private_subnets
      tags           = merge(var.tags, { Name = "eks-node-general-purpose" })
    }
  }
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "vpc-cni"
  addon_version = "v1.20.1-eksbuild.3"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "kube-proxy"
  addon_version = "v1.33.3-eksbuild.6"
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "coredns"
  addon_version = "v1.12.3-eksbuild.1"
  depends_on    = [module.eks]
}

resource "helm_release" "nginx_ingress" {
  depends_on       = [aws_eks_addon.vpc_cni, aws_eks_addon.kube_proxy, aws_eks_addon.coredns]
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.13.2"
  namespace        = "ingress-nginx"
  create_namespace = true

  values = [
    <<-EOT
controller:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      service.beta.kubernetes.io/aws-load-balancer-subnets: ${join(",", module.vpc.public_subnets)}
EOT
  ]

  timeout = 900
}
