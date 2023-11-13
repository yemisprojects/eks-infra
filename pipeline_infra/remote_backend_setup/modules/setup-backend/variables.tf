################################################################################
# DYNAMO
################################################################################
variable "table_name" {
  description = "Name of dynamodb table"
  type        = string
}

variable "table_tags" {
  description = "Tags to add to dynamodb table"
  type        = map(string)
  default     = {}
}

################################################################################
# S3
################################################################################
variable "bucket_name" {
  description = "Name of S3 bucket"
  type        = string
}

variable "force_destroy" {
  description = "Delete all objects from the bucket without error"
  type        = bool
  default     = true #SET TO FALSE IN PROD!!
}

variable "bucket_tags" {
  description = "Tags to assign to bucket"
  type        = map(string)
  default     = {}
}
