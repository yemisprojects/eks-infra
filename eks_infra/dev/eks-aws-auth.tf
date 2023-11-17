locals {
  configmap_roles = [
    {
      rolearn  = aws_iam_role.eks_nodegroup_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = aws_iam_role.karpenter_instance_node_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]
}

resource "kubernetes_config_map_v1" "aws_auth" {

  depends_on = [aws_eks_cluster.eks_cluster, aws_iam_role.karpenter_instance_node_role]
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = yamlencode(local.configmap_roles)
  }
}
