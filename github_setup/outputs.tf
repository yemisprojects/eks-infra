
################################################################################
# Github actions variables
################################################################################
output "eks_tfstate_bucket" {
  description = "Name of the bucket for S3 eks backend"
  value       = module.eks_backend.s3_bucket_id
}

output "eks_tfstate_db" {
  description = "Name of dynamodb table for eks remote state"
  value       = module.eks_backend.table_id
}

output "cicd_tfstate_bucket" {
  description = "Name of the bucket for S3 pipeline backend"
  value       = module.pipeline_backend.s3_bucket_id
}

output "cicd_tfstate_db" {
  description = "Name of dynamodb table for pipeline remote state"
  value       = module.pipeline_backend.table_id
}

output "aws_role" {
  description = "github actions role"
  value       = aws_iam_role.github_role.arn
}
