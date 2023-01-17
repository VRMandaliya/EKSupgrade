module "clean_backend_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "3.5.0"

  identifier = "${local.name}-backend"

  engine               = "postgres"
  engine_version       = "14.5"
  family               = "postgres14"
  major_engine_version = "14"
  instance_class       = "db.t3.small"

  allow_major_version_upgrade = true
  apply_immediately           = true

  allocated_storage     = 20
  max_allocated_storage = 100

  name     = "cleaning"
  username = "root"
  password = data.aws_ssm_parameter.root_password.value
  port     = 5432

  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.rds_backend_security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 14

  tags = {
    Product   = "clean-me"
    Layer     = "backend"
    Component = "db"
    Terraform = "https://github.com/nn-team/cleaning_backend/tree/main/resources/terraform/eu-west-1"
  }
}
