variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  validation {
    condition     = can(regex("^t2.mic", var.instance_type))
    error_message = "Ec2 instance type should be t2.micro."
  }
}

variable "vpc_id" {
  type = string

}

variable "subnet_id" {
  type = string
}

data "template_file" "user_data" {
  template = file("${path.module}/userdata.yml")
}

data "aws_ami" "ami_id" {
  most_recent = true
  owners      = ["137112412989"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20220316.0-x86_64*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}