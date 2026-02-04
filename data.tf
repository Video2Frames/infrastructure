data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks]
  name       = module.eks.cluster_name
}

data "kubernetes_service" "nginx_ingress" {
  depends_on = [helm_release.nginx_ingress]
  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}
