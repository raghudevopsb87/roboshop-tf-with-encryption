resource "aws_security_group" "instances" {
  for_each      = var.components
  name        = "${each.key}-${var.env}-sg"
  description = "${each.key}-${var.env}-sg"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${each.key}-${var.env}-sg"
  }
}

resource "aws_security_group_rule" "instances" {
  for_each          = var.components
  type              = "ingress"
  from_port         = each.value["port"]
  to_port           = each.value["port"]
  protocol          = "tcp"
  cidr_blocks       = each.value["allow_cidr"]
  security_group_id = aws_security_group.instances[each.key].id
}

resource "aws_security_group_rule" "ssh" {
  for_each          = var.components
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.bastion_ips
  security_group_id = aws_security_group.instances[each.key].id
}

resource "aws_security_group_rule" "allow_all" {
  for_each          = var.components
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_security_group.instances[each.key].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "instances" {
  for_each      = var.components
  ami           = var.ami
  instance_type = each.value["instance_type"]
  vpc_security_group_ids = [aws_security_group.instances[each.key].id]
  subnet_id = aws_subnet.private[0].id

  root_block_device {
    encrypted   = true
    kms_key_id  = var.kms
  }

  tags = {
    Name = each.key
  }

}

resource "aws_route53_record" "a-records" {
  for_each      = var.components
  zone_id = var.zone_id
  name    = "${each.key}-dev"
  type    = "A"
  ttl     = 30
  records = [aws_instance.instances[each.key].private_ip]
}

resource "null_resource" "ansible" {

  depends_on = [
    aws_instance.instances,
    aws_route53_record.a-records
  ]


  for_each      = var.components

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ec2-user"
      password = "DevOps321"
      host     = aws_instance.instances[each.key].private_ip
    }

    inline = [
      "sudo dnf install ansible -y",
      #"sudo dnf install python3.13-pip -y",
      #"sudo pip3.11 install ansible",
      "ansible-pull -i localhost, -U https://github.com/raghudevopsb87/roboshop-ansible-templates.git main.yml -e component=${each.key} -e env=dev"
    ]

  }

}

