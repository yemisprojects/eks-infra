
################################################################################
# OUTPUTS eks_backend
################################################################################
output "main_s3_bucket_id" {
  description = "Name of the bucket for S3 backend (ami-pipeline)"
  value       = module.pipeline.s3_bucket_id
}

output "main_table_id" {
  description = "Name of dynamodb table for remote state (ami-pipeline)"
  value       = module.pipeline.table_id
}
