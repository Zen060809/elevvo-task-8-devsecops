
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id  = aws_vpc.main.id
  ingress = []
  egress  = []

  tags = {
    Name = "${var.project_name}-default-sg"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "${var.project_name}-private-subnet"
  }
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-database-sg"
  description = "Restricts database workload network traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound traffic only within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-database-sg"
  }
}

resource "aws_network_interface" "database" {
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.database.id]
  description     = "Private network interface for database workloads"

  tags = {
    Name = "${var.project_name}-database-eni"
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs" {
  role       = aws_iam_role.vpc_flow_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonVPCFlowLogsServiceRolePolicy"
}

resource "aws_kms_key" "vpc_flow_logs" {
  description             = "Encrypt VPC flow logs for ${var.project_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Name = "${var.project_name}-flow-logs-key"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}/flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.vpc_flow_logs.arn
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn

  depends_on = [
    aws_iam_role_policy_attachment.vpc_flow_logs
  ]

  tags = {
    Name = "${var.project_name}-vpc-flow-logs"
  }
}
