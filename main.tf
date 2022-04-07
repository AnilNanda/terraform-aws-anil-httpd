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
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIt4bNFgChOdk78YbuWY8nvVhmQCFa3P19ZPksPRNCJ2Kv4P4SydvBPpfkuNOhfEUJzywnsI/eCtgEqXru6G4JVRYq1RZLP2+fvrfDHC7OWUNnZHacFe2NBxRW9ivallWdwQfIfGN9Q/R3hXjWOYDSXqnHXfOx9N1D/gD7HNcF63vtJEsd0ntV8MAxJcZJWGrB6MPNWCC2gcb3FGMZsZQQOat4oTzWZ1so8+gnB1iVwTe2VJ/9Bl2y/3oeKMxdsTn7vlFlJtFElqcIj2Z725ED4W1cnk0FpHkEMLunINDEOOuzyZbtV/8+EvDHyFgflJ2AHjBO3C1bHlty+62veO6VUMF+AGAms2sQ+ModDQ6Vdvm+4u0jhN2p1l6eX0mJES6TYPpYEZlRBdm3y73GpZiKmz22xrbm0vLNVUw5o+94VS17pznKbO1eTxULqTkrxSZF34WV0CsBPpxXNF220AzHJrWI1SKe5ORIhWv47ySI6Nr1WInmc65ZiEmUpkq4QUE= anil"
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
      cidr_blocks      = ["111.92.89.198/32"]
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
    command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.webserver[0].id}"
  }
}
