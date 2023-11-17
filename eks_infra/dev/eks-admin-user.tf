resource "aws_iam_user" "admin_user" {
  name          = var.secondary_eks_admin
  path          = "/"
  force_destroy = true
}

# Resource: Admin Access Policy - Attach it to admin user
resource "aws_iam_user_policy_attachment" "admin_user" {
  user       = aws_iam_user.admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
