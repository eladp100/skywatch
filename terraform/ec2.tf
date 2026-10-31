resource "aws_instance" "skywatch" {
  for_each = local.servers

  ami                    = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type          = each.value.instance_type
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = [aws_security_group.skywatch.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  associate_public_ip_address = true

  credit_specification {
    cpu_credits = var.cpu_credits
  }

  lifecycle {
    ignore_changes = [
      credit_specification
    ]
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = var.delete_root_volume_on_termination
    encrypted             = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = each.key
  }
}
