resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

# Only allow inbound Postgres traffic from the EKS node/pod security group.
# VERIFY: confirm the exact output name in your installed module version
# (see .terraform/modules/eks/outputs.tf) -- this assumes `node_security_group_id`.

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # requirement: private subnet only

  multi_az                = false # set true for production HA (doubles cost)
  backup_retention_period = 1
  deletion_protection     = false # flip to true before anything resembling production
  skip_final_snapshot     = true  # flip to false + set final_snapshot_identifier for production

  tags = { Name = "${var.project_name}-db" }
}