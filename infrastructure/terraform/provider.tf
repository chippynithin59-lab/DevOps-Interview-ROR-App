provider "aws" {
  region = var.aws_region
}
# These two providers talk to the EKS cluster itself, so they depend on
# outputs from the eks.tf module (created later). Terraform can handle this
# forward reference fine, but note kubectl/helm calls to the cluster only
# succeed once eks.tf has actually run.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}