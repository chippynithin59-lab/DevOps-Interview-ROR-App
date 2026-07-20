# ============================================================
# ALB security group — the only security group in this project
# that accepts traffic from the public internet.
# ============================================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS from the internet to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Uncomment once you attach an ACM certificate for HTTPS
  # ingress {
  #   description = "HTTPS from internet"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# ============================================================
# EKS node security group rule — explicitly allows the ALB (and
# only the ALB) to reach pods on the Nginx container port.
#
# The EKS module already creates a base node security group
# (module.eks.node_security_group_id); this adds one explicit
# rule to it rather than creating a second, competing SG on the
# nodes themselves. Node ENIs can only cleanly belong to one
# "primary" SG from the module, so we attach rules to it instead
# of creating a rival aws_security_group here.
# ============================================================
resource "aws_security_group_rule" "alb_to_nodes" {
  type                     = "ingress"
  description              = "Allow ALB to reach pods on port 80"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id # VERIFY this output name for your module version
  source_security_group_id = aws_security_group.alb.id
}

# ============================================================
# RDS security group — only reachable from EKS worker nodes.
# ============================================================
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow Postgres from EKS worker nodes only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}