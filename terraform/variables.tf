
variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "me-central-1"
}

variable "project_name" {
  description = "Name prefix for project resources"
  type        = string
  default     = "elevvo-devsecops"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
