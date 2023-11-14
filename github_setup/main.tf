################################################################################
# REMOTE BACKEND FOR EKS INFRASTRUCTURE
################################################################################
module "eks_backend" {
  source = "../modules/backend"

  table_name  = "dev-eks-cluster"
  bucket_name = "eks-tfstate-${random_integer.backend.id}"
}

module "pipeline_backend" {
  source = "../modules/backend"

  table_name  = "cicd-jenkins"
  bucket_name = "cicd-tfstate-${random_integer.backend.id}"
}

resource "random_integer" "backend" {
  min = 100000000000
  max = 999999999999
}

resource "aws_iam_openid_connect_provider" "this" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

resource "aws_iam_role" "github_role" {
  name = "github_actions_role"

  assume_role_policy = <<POLICY
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${aws_iam_openid_connect_provider.this.arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:${var.github_username}/${var.repo_name}:*"
                }
            }
        }
    ]
}
POLICY
}

#Use principle of least priviledge. Admin access is for demo purposes only
#backend VPC, EC2 EKS infra access required
resource "aws_iam_role_policy_attachment" "tf_github_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.github_role.name
}
