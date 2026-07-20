module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project_name}-eks"
  kubernetes_version = var.cluster_version


  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  endpoint_public_access = true

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  encryption_config = null

  # ADD THIS BLOCK — without it, v21 installs none of these by default,
  # leaving nodes permanently NotReady with no pod networking.
  addons = {
    vpc-cni = {
      before_compute = true
    }
    kube-proxy = {}
    coredns    = {}
  }

  eks_managed_node_groups = local.node_groups

  tags = {
    Project = var.project_name
  }
}