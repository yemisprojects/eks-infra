################################################################################
# REMOTE BACKEND FOR EKS INFRASTRUCTURE
################################################################################
module "pipeline" {
  source = "./modules/setup-backend"

  table_name  = "pipeline"
  bucket_name = "pipeline-tfstate-${random_integer.this.id}"
}

resource "random_integer" "this" {
  min = 100000000000
  max = 999999999999
}
