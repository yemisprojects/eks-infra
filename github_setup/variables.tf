variable "aws_region" {
  description = "Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "github_username" {
  description = "Github username"
  type        = string
  default     = "yemisprojects"
}

variable "repo_name" {
  description = "github repo name"
  type        = string
  default     = "eks-infra"
}
