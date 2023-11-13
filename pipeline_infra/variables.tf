variable "aws_region" {
  description = "Region to deploy EKS"
  type        = string
  default     = "us-east-1"
}

################################################################################
# VPC
################################################################################

variable "vpc_name" {
  description = "name of  VPC"
  type        = string
  default     = "tooling-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpc_public_subnets" {
  description = "VPC Public Subnets"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "instance_type" {
  description = "ec2 instance type"
  type        = string
  default     = "t3.large"
}

variable "instance_type_sonarqube" {
  description = "ec2 instance type"
  type        = string
  default     = "t3.large"
}


variable "ec2_key_name" {
  type        = string
  description = "Name of ec2 key"
  default     = "mobia"
}
