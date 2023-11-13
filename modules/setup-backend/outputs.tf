output "s3_bucket_id" {
  description = "Name of the bucket for S3 backend"
  value       = aws_s3_bucket.this.id
}

# output "s3_bucket_arn" {
#   description = "ARN of the bucket for S3 backend"
#   value       = aws_s3_bucket.this.arn
# }

output "table_id" {
  description = "Name of dynamodb table for remote state"
  value       = aws_dynamodb_table.this.id
}

# output "table_arn" {
#   description = "Arn of dynamodb table for remote state"
#   value       = aws_dynamodb_table.this.arn
# }
