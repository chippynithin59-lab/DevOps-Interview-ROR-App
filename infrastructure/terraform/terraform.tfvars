aws_region   = "us-east-1"
project_name = "ror-app"

azs = ["us-east-1a", "us-east-1b"]
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
db_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

cluster_version = "1.31"
node_instance_types = ["t3.medium"]
node_desired_size = 2
node_min_size = 2
node_max_size = 4

db_name = "ror_app_production"
db_username = "ror_app"
db_instance_class = "db.t3.micro"
db_engine_version = "13.23"