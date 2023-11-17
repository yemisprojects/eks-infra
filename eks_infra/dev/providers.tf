terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.65"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }

  backend "s3" {}
  # backend "s3" {
  #   bucket = "eks-tfstate-454544241908"
  #   key    = "terraform.tfstate"
  #   region = "us-east-1"
  #   dynamodb_table = "dev-eks-cluster"
  # }

}

provider "aws" {
  region = var.aws_region
}

#https://stackoverflow.com/questions/70962800/error-kube-system-configmaps-dial-tcp-127-0-0-180-connect-connection-refused
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.id
}

provider "kubernetes" {

  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}
