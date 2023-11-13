
################################################################################
# OUTPUTS eks_backend
################################################################################
output "eks_s3_bucket_id" {
  description = "Name of the bucket for S3 eks backend"
  value       = module.eks_backend.s3_bucket_id
}

output "eks_table_id" {
  description = "Name of dynamodb table for eks remote state"
  value       = module.eks_backend.table_id
}

output "pipeline_s3_bucket_id" {
  description = "Name of the bucket for S3 pipeline backend"
  value       = module.pipeline_backend.s3_bucket_id
}

output "pipeline_table_id" {
  description = "Name of dynamodb table for pipeline remote state"
  value       = module.pipeline_backend.table_id
}
