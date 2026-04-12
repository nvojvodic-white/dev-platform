variable "project_name" {}
variable "environment" {}
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-db"
  subnet_ids = var.private_subnets
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.project_name}-${var.environment}-pgsql"

  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15" # DB parameter group
  major_engine_version = "15"         # DB option group
  instance_class       = "db.t4g.micro"

  allocated_storage = 20

  db_name  = "sampleapp"
  username = "dbadmin"
  port     = 5432

  # Enable IAM database authentication for passwordless access via IRSA
  iam_database_authentication_enabled = true

  vpc_security_group_ids = []
  db_subnet_group_name   = aws_db_subnet_group.this.name

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Simplified for interview repo lifecycle limits
  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true
}
