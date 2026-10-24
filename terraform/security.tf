resource "aws_security_group" "skywatch" {
  name_prefix = "skywatch-"
  description = "Security group for SkyWatch K3s servers"
  vpc_id      = var.vpc_id

  egress = []

  tags = {
    Name = "skywatch-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "internal" {
  security_group_id            = aws_security_group.skywatch.id
  referenced_security_group_id = aws_security_group.skywatch.id
  ip_protocol                  = "-1"

  description = "Allow communication between SkyWatch K3s nodes"
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.skywatch.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  description = "Allow outbound traffic for updates and dependencies"
}
