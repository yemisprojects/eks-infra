################################################################################
# ARGO-CD
################################################################################
#kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.29.1"

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
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

  depends_on = [helm_release.karpenter,
    kubectl_manifest.karpenter_node_template,
    kubectl_manifest.karpenter_provisioner,
    module.vpc
  ]
}
