terraform {

  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.65"
    }

    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }

  }

  backend "s3" {}

  # backend "s3" {
  #   bucket = "eks-infra-tfstate-644802181882"
  #   key    = "prod/eks-cluster/terraform.tfstate"
  #   region = "us-east-1"

  #   dynamodb_table = "prod-eks-cluster"
  # }

}

provider "aws" {
  region = var.aws_region
}
