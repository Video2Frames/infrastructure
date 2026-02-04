resource "aws_db_subnet_group" "hackathon_db_subnet_group" {
  name        = "hackathon-subnet-group"
  subnet_ids  = module.vpc.private_subnets
  description = "Main subnet group for hackathon PostgreSQL RDS instance"
  tags        = var.tags
}

resource "aws_db_instance" "hackathon_psql_db" {
  identifier              = "hackathon-psql-db"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "17.6"
  instance_class          = "db.t3.micro"
  username                = var.db_user
  password                = var.db_password
  parameter_group_name    = "default.postgres17"
  skip_final_snapshot     = true
  publicly_accessible     = false
  storage_type            = "gp2"
  multi_az                = false
  backup_retention_period = 0
  tags                    = var.tags
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.hackathon_db_subnet_group.name
  db_name                 = "soat"
}

resource "aws_security_group" "rds" {
  name        = "hackathon-psql-db-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound PostgreSQL traffic from Lambda and EKS nodes
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.lambda.id,
      module.eks.node_security_group_id
    ]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
