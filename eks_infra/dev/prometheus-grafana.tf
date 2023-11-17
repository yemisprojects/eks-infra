resource "helm_release" "prometheus" {

  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "prometheus"
  create_namespace = true
  version          = "51.3.0"
  values = [
    file("./prometheus_helm_values/values.yaml")
  ]
  timeout = 2000


  set {
    name  = "podSecurityPolicy.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = false
  }

  set {
    name = "server\\.resources"
    value = yamlencode({
      limits = {
        cpu    = "200m"
        memory = "50Mi"
      }
      requests = {
        cpu    = "100m"
        memory = "30Mi"
      }
    })
  }

  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth,
    aws_eks_node_group.eks_ng_private,
    kubectl_manifest.karpenter_provisioner,
    kubectl_manifest.karpenter_node_template

  ]

}

resource "kubectl_manifest" "prometheus" {
  yaml_body = <<-YAML
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: grafana
      namespace: prometheus
      annotations:
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/load-balancer-name: prometheus-ingress
        alb.ingress.kubernetes.io/target-type: ip
    spec:
      ingressClassName: my-aws-ingress-class
      rules:
        - host: ${var.grafana_domain_name}
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: prometheus-grafana
                    port:
                      number: 80
  YAML

  depends_on = [
    helm_release.prometheus,
    helm_release.karpenter,
    aws_eks_node_group.eks_ng_private
  ]
}


resource "helm_release" "metrics_server_release" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth,
    aws_eks_node_group.eks_ng_private,
    kubectl_manifest.karpenter_provisioner,
    kubectl_manifest.karpenter_node_template

  ]
}
