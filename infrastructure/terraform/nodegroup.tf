# Node group configuration lives here as a local, referenced by the eks module
# block in eks.tf. Keeping it separate makes it easy to add a second node
# group later (e.g. a spot-instance pool) without touching eks.tf itself.
locals {
  node_groups = {
    default = {
      instance_types = var.node_instance_types
      desired_size   = var.node_desired_size
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      subnet_ids     = aws_subnet.private[*].id

      capacity_type = "ON_DEMAND" # switch to "SPOT" to cut cost, at the risk of interruption

      labels = {
        role = "app"
      }

      update_config = {
        max_unavailable = 1
      }
    }
  }
}