################################################################################
# KARPENTER
################################################################################
data "aws_iam_policy_document" "karpenter_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json
  name               = "karpenter-controller"
}

resource "aws_iam_policy" "karpenter_controller" {
  policy = file("./_karpenter/controller-trust-policy.json")
  name   = "KarpenterController"
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_role_attachment" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

#Attach to nodes
resource "aws_iam_instance_profile" "karpenter" {
  name       = "KarpenterNodeInstanceProfile"
  role       = aws_iam_role.eks_nodegroup_role.name
  depends_on = [aws_eks_node_group.eks_ng_private]
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = "v0.16.3"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.id
  }

  set {
    name  = "clusterEndpoint"
    value = aws_eks_cluster.eks_cluster.endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  set {
    name  = "replicas"
    value = 1
  }

}

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
      apiVersion: karpenter.sh/v1alpha5
      kind: Provisioner
      metadata:
        name: default
      spec:
        ttlSecondsAfterEmpty: 60 # scale down nodes after 60 seconds without workloads (excluding daemons)
        ttlSecondsUntilExpired: 604800 # expire nodes after 7 days (in seconds) = 7 * 60 * 60 * 24
        limits:
          resources:
            cpu: 100 # limit to 100 CPU cores
        requirements:
          # Include general purpose instance families
          - key: karpenter.k8s.aws/instance-family
            operator: In
            values: [c5, m5, r5]
          # Exclude small instance sizes
          # - key: karpenter.k8s.aws/instance-size
          #   operator: NotIn
          #   values: [nano, micro, small, large]
        providerRef:
          name: my-provider
  YAML

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: my-provider
    spec:
      subnetSelector:
        kubernetes.io/cluster/${var.cluster_name}: owned
      securityGroupSelector:
        kubernetes.io/cluster/${var.cluster_name}: owned
  YAML

  depends_on = [kubectl_manifest.karpenter_provisioner]
}
