################################################################################
# REMOTE BACKEND FOR EKS INFRASTRUCTURE
################################################################################
module "eks_backend" {
  source = "../modules/backend"

  table_name  = "dev-eks-cluster"
  bucket_name = "eks-tfstate-${random_integer.backend.id}"
}

module "pipeline_backend" {
  source = "../modules/backend"

  table_name  = "cicd-jenkins"
  bucket_name = "cicd-tfstate-${random_integer.backend.id}"
}

resource "random_integer" "backend" {
  min = 100000000000
  max = 999999999999
}
