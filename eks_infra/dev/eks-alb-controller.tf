################################################################################
# AWS LOAD BALANCER CONTROLLER
################################################################################
resource "helm_release" "loadbalancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.aws_region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller_role.arn
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.id
  }

  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth,
    aws_eks_node_group.eks_ng_private,
    aws_iam_role.aws_load_balancer_controller_role,
    helm_release.argocd
  ]

}

################################################################################
# DATA SOURCES
################################################################################
resource "kubernetes_ingress_class_v1" "ingress_class_default" {
  depends_on = [helm_release.loadbalancer_controller]
  metadata {
    name = "my-aws-ingress-class"
    # annotations = {
    #   "ingressclass.kubernetes.io/is-default-class" = "true"
    # }
  }
  spec {
    controller = "ingress.k8s.aws/alb"
  }
}

################################################################################
# DATA SOURCES
################################################################################
data "http" "aws_load_balancer_controller_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

################################################################################
# LOCALS
################################################################################
locals {
  aws_iam_oidc_connect_provider_extract_from_arn = element(split("oidc-provider/", aws_iam_openid_connect_provider.eks.arn), 1)
}

################################################################################
# Role for AWS Load Balancer controller
################################################################################
resource "aws_iam_role" "aws_load_balancer_controller_role" {
  name = "aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:aud" : "sts.amazonaws.com",
            "${local.aws_iam_oidc_connect_provider_extract_from_arn}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      },
    ]
  })

}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attachment" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
  role       = aws_iam_role.aws_load_balancer_controller_role.name
}

resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  name        = "aws-load-balancer-controller-policy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.aws_load_balancer_controller_iam_policy.response_body
}
