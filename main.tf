terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.public_key
}

locals {
  ingress_rules = [
    {
      port        = 22,
      description = "SSH"
    },
    {
      port        = 80
      description = "HTTP"
    }
  ]
}

resource "aws_security_group" "web_sg" {
  name        = "webserver-sg"
  description = "SG for httpd webserver"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = "tcp"
      cidr_blocks      = [var.inbound_ip]
      prefix_list_ids  = []
      ipv6_cidr_blocks = []
      security_groups  = []
      self             = false
    }
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids  = []
    ipv6_cidr_blocks = []
    security_groups  = []
    self             = false
  }
tags = {
 "Name" = "webserver-sg"
}

resource "aws_instance" "webserver" {
  count           = 1
  ami             = data.aws_ami.ami_id.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.deployer.key_name
  user_data       = data.template_file.user_data.rendered
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id = var.subnet_id
  tags = {
    "Name" = "webserver-${count.index}"
  }
}

resource "null_resource" "status" {
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.webserver[0].id} --region us-east-1"
  }
}
