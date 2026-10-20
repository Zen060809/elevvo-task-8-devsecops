resource "aws_security_group" "insecure_test" {
  name        = "insecure-test-security-group"
  description = "Intentionally insecure test for Checkov"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Intentionally unsafe SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
