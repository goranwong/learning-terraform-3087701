data "aws_ami" "app_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.blog_sg.id]

# Install Java and Tomcat automatically on Amazon Linux 2023
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y java-17-amazon-corretto-devel tomcat10 tomcat10-webapps tomcat10-admin-webapps
              systemctl enable tomcat10
              systemctl start tomcat10
              EOF

  tags = {
    Name = "Learning Terraform"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "6.0.0"
  name = "blog_new"
  
  vpc_id = data.aws_vpc.default.id
 
  ingress_rules = {
      http = {
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
        cidr_ipv4   = "0.0.0.0/0"
      }
      https = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }

    egress_rules = {
      all = {
        ip_protocol = "-1"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
}


resource "aws_security_group" "blog" {
  name        = "blog"
  description = "Allow http and https in. Allow everything out"

  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "blog_http_in" {
  type        = "ingress"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id 
}

resource "aws_security_group_rule" "blog_https_in" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id 
}

resource "aws_security_group_rule" "blog_ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] 
  security_group_id = aws_security_group.blog.id
}

resource "aws_security_group_rule" "blog_everthing_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.blog.id 
}