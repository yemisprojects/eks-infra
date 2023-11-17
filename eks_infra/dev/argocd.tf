################################################################################
# ARGO-CD
################################################################################
resource "helm_release" "argocd" {

  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.29.1"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 3600

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "redis-ha.enabled"
    value = true
  }

  set {
    name  = "server.autoscaling.enabled"
    value = true
  }

  set {
    name  = "server.autoscaling.minReplicas"
    value = 2
  }

  set {
    name  = "applicationSet.replicaCount"
    value = 2
  }

  set {
    name  = "controller.replicas"
    value = 1
  }

  depends_on = [
    helm_release.karpenter,
    kubectl_manifest.karpenter_node_template,
    kubectl_manifest.karpenter_provisioner,
    aws_eks_node_group.eks_ng_private,
    helm_release.prometheus,

  ]
}
