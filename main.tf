variable "default_port" {
  description = "Server port for HTTP requests."
  default = 8080
}

data "local_file" "start_script" {
  filename = "start.sh"
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "saltstack" {
  ami = "ami-0c59fb6cd1d16a1ce"
  instance_type = "t2.micro"
  user_data = <<-EOF
              #!/bin/bash
              echo "{"health":"ok"}" > index.html
              nohup busybox httpd -f -p "${var.default_port}" &
              EOF 

  tags = {
    Name = "saltstack"
  }

  vpc_security_group_ids = [
    "${aws_security_group.instance.id}"
  ]
}

resource "aws_security_group" "instance" {
  name = "saltstack-security-group"

  ingress {
    from_port = "${var.default_port}"
    to_port = "${var.default_port}"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}


output "public_ip" {
  value = "${aws_instance.saltstack.public_ip}"
}
