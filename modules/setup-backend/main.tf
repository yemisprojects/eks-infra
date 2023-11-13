################################################################################
# DynamoDB TF state Lock
################################################################################
resource "aws_dynamodb_table" "this" {

  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  point_in_time_recovery {
    enabled = true
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.table_tags
}

################################################################################
# S3 Backend
################################################################################
resource "aws_s3_bucket" "this" {

  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.bucket_tags
}

resource "aws_s3_bucket_public_access_block" "this" {

  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "this" {

  bucket = aws_s3_bucket.this.id
  policy = templatefile("${path.module}/templates/s3_bucket_policy.tftpl", { bucket_name = var.bucket_name })
}
