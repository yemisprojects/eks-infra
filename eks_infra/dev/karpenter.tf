################################################################################
# KARPENTER
################################################################################
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  # We will be using AWS Public ECR to download needed chart as mentioned Above.
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "v0.32.1"
  timeout             = 3000

  values = [file("./karpenter_helm_values/values_k.yaml")]

  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.eks_cluster.id
  }

  set {
    name  = "settings.clusterEndpoint"
    value = aws_eks_cluster.eks_cluster.endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }

  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth,
    aws_eks_node_group.eks_ng_private,
    aws_eks_cluster.eks_cluster
  ]

}
/*resource "helm_release" "karpenter" {

  name             = "karpenter"
  repository       = "https://charts.karpenter.sh"
  chart            = "karpenter"
  version          = "v0.16.3"
  namespace        = "karpenter"
  create_namespace = true
  timeout          = 3000

  values = [file("./karpenter_helm_values/values.yaml")]

  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }

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

  #nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms set in values.yaml
  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth,
    aws_eks_node_group.eks_ng_private,
    aws_eks_cluster.eks_cluster
  ]

}*/

################################################################################
# Role for kapenter EC2 nodes
################################################################################
resource "aws_iam_role" "karpenter_instance_node_role" {
  name = "karpenter-instance-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_instance_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_instance_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_instance_node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_instance_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_instance_node_ec2_container_registry_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_instance_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_instance_node_ssm_managed_instance_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_instance_node_role.name
}

#Attach to nodes
resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile"
  role = aws_iam_role.karpenter_instance_node_role.name
}

################################################################################
# Role for kapenter controller
################################################################################
resource "aws_iam_role" "karpenter_controller" {
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role_policy.json
  name               = "karpenter-controller"
}

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

resource "aws_iam_policy" "karpenter_controller" {
  policy = file("./karpenter_controller_policy/controller-trust-policy.json")
  name   = "KarpenterController"
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_role_attachment" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}




################################################################################
# EC2 Default provisioner
################################################################################
resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
    name: default
    spec:
    template:
        spec:
        requirements:
            - key: kubernetes.io/os
            operator: In
            values: ["linux"]
            - key: karpenter.k8s.aws/instance-category
            operator: In
            values: ["c", "m", "r", "t"]
            - key: karpenter.k8s.aws/instance-generation
            operator: Gt
            values: ["3"]
        nodeClassRef:
            name: default
    limits:
        cpu: 100
    disruption:
        consolidationPolicy: WhenUnderutilized
        expireAfter: 720h # 30 * 24h = 720h
  YAML

  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth,
    aws_eks_cluster.eks_cluster,
    aws_eks_node_group.eks_ng_private
  ]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
    name: default
    spec:
    amiFamily: AL2 # Amazon Linux 2
    role: "karpenter-instance-node-role"
    subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
    securityGroupSelectorTerms:
        - tags:
            kubernetes.io/cluster/${var.cluster_name}: owned
  YAML

  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth,
    aws_eks_cluster.eks_cluster,
    aws_eks_node_group.eks_ng_private
  ]
}
