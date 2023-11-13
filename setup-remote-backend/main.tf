################################################################################
# REMOTE BACKEND FOR EKS INFRASTRUCTURE
################################################################################
module "eks_backend" {
  source = "../modules/setup-backend"

  table_name  = "prod-eks-cluster"
  bucket_name = "eks-infra-tfstate-${random_integer.eks_backend.id}"
}

resource "random_integer" "eks_backend" {
  min = 100000000000
  max = 999999999999
}


module "pipeline_backend" {
  source = "../modules/setup-backend"

  table_name  = "prod-eks-cluster"
  bucket_name = "eks-infra-tfstate-${random_integer.pipeline_backend.id}"
}

resource "random_integer" "pipeline_backend" {
  min = 100000000000
  max = 999999999999
}
