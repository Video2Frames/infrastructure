# Lambda function resources
resource "aws_lambda_layer_version" "psycopg2" {
  filename            = "lambda/layer.zip"
  layer_name          = "psycopg2-lambda-layer"
  compatible_runtimes = ["python3.13"]

  depends_on = [null_resource.build_lambda_layer]
}

resource "aws_lambda_function" "init_db" {
  filename      = "lambda/function.zip"
  function_name = "hackathon-db-init"
  role          = aws_iam_role.lambda_role.arn
  handler       = "init_db.lambda_handler"
  runtime       = "python3.13"
  timeout       = 300

  environment {
    variables = {
      DB_HOST     = split(":", aws_db_instance.hackathon_psql_db.endpoint)[0]
      DB_PORT     = split(":", aws_db_instance.hackathon_psql_db.endpoint)[1]
      DB_NAME     = aws_db_instance.hackathon_psql_db.db_name
      DB_USER     = aws_db_instance.hackathon_psql_db.username
      DB_PASSWORD = var.db_password
    }
  }

  layers = [aws_lambda_layer_version.psycopg2.arn]

  vpc_config {
    subnet_ids         = aws_db_subnet_group.hackathon_db_subnet_group.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.package_lambda
    ]
  }

  depends_on = [
    aws_db_instance.hackathon_psql_db,
    aws_lambda_layer_version.psycopg2,
    null_resource.package_lambda

  ]
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "hackathon-db-init-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for VPC access
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  name        = "hackathon-db-init-lambda-sg"
  description = "Security group for DB initialization Lambda"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Build Lambda layer
resource "null_resource" "build_lambda_layer" {
  triggers = {
    requirements = filemd5("${path.module}/lambda/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module}/lambda && \
      mkdir -p python/lib/python3.13/site-packages && \
      python -m pip install -r requirements.txt -t python/lib/python3.13/site-packages/ && \
      zip -r layer.zip python/
    EOF
  }
}

# Package Lambda function
resource "null_resource" "package_lambda" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
      cd ${path.module}/lambda && \
      cp ../scripts/create_status_db.sql . && \
      cp ../scripts/create_identification_db.sql . && \
      cp ../scripts/init_status_db.sql . && \
      cp ../scripts/init_identification_db.sql . && \
      zip function.zip init_db.py create_status_db.sql create_identification_db.sql init_status_db.sql init_identification_db.sql
    EOF
  }
}

# Invoke Lambda after RDS creation
resource "null_resource" "invoke_lambda" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name ${aws_lambda_function.init_db.function_name} /dev/null"
  }

  depends_on = [
    aws_lambda_function.init_db,
    aws_db_instance.hackathon_psql_db
  ]
}
