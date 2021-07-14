variable "PUBLIC_KEY" {}
variable "PRIVATE_KEY" {}
variable "API_KEY" {}
variable "DOWNLOAD_EMAIL" {}
variable "DOWNLOAD_TOKEN" {}
variable "TRUSTED_IP_CIDR" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

resource "aws_key_pair" "xsoar_terraform_key" {
  key_name   = "AWS Terraform XSOAR SSH Key"
  public_key = "${file(var.PUBLIC_KEY)}"
}

#######################
/* Environment Setup */
#######################

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_vpc" "xsoar-lab-env" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "xsoar-lab-subnet" {
  cidr_block = "${cidrsubnet(aws_vpc.xsoar-lab-env.cidr_block, 3, 1)}"
  vpc_id = "${aws_vpc.xsoar-lab-env.id}"
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
}


resource "aws_security_group" "xsoar-lab-sg" {
  name = "allow-all-sg"
  vpc_id = "${aws_vpc.xsoar-lab-env.id}"
  ingress {
    cidr_blocks = [
      "${var.TRUSTED_IP_CIDR}"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  ingress {
    cidr_blocks = [
      "${var.TRUSTED_IP_CIDR}"
    ]
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_internet_gateway" "xsoar-lab-gw" {
  vpc_id = "${aws_vpc.xsoar-lab-env.id}"
}

resource "aws_route_table" "xsoar-lab-route-table" {
  vpc_id = "${aws_vpc.xsoar-lab-env.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.xsoar-lab-gw.id}"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.xsoar-lab-subnet.id}"
  route_table_id = "${aws_route_table.xsoar-lab-route-table.id}"
}



###################
/* XSOAR Install */
###################

resource "aws_instance" "xsoar-lab" {
  ami           = "ami-090717c950a5c34d3"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.xsoar_terraform_key.key_name}"
  security_groups = ["${aws_security_group.xsoar-lab-sg.id}"]
  subnet_id = "${aws_subnet.xsoar-lab-subnet.id}"
  associate_public_ip_address = true
  tags = {
    Name = "XSOAR"
  }
  root_block_device {
    volume_size = 50
  }
}


resource "null_resource" "bash" {
  depends_on = [aws_instance.xsoar-lab]
  connection {
    host        = "${aws_instance.xsoar-lab.public_ip}"
    user        = "ubuntu"
    type        = "ssh"
    private_key = "${file(var.PRIVATE_KEY)}"
    timeout     = "2m"
  }
  provisioner "file" {
    source      = "./secrets"
    destination = "/tmp"
  }
  provisioner "file" {
    source      = "./bin/xsoar-install.sh"
    destination = "/tmp/xsoar-install.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/xsoar-install.sh",
      "/tmp/xsoar-install.sh ${var.API_KEY} ${var.DOWNLOAD_TOKEN} ${var.DOWNLOAD_EMAIL}"
    ]
  }
}



#####################
/* Vulnerable Host */
#####################
/*
resource "aws_instance" "vulnerable-host" {
  ami           = "ami-0bc06212a56393ee1"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.xsoar_terraform_key.key_name}"
  subnet_id = "${aws_subnet.xsoar-lab-subnet.id}"
  security_groups = ["${aws_security_group.xsoar-lab-sg.id}"]
  associate_public_ip_address = true
  tags = {
    Name = "Vulnerable Host"
  }
  root_block_device {
    volume_size = 50
  }
  connection {
    host        = "${aws_instance.vulnerable-host.public_ip}"
    user        = "centos"
    type        = "ssh"
    private_key = "${file(var.PRIVATE_KEY)}"
    timeout     = "2m"
  }
  provisioner "file" {
    source = "./secrets/Linux_Agent.sh"
    destination = "/tmp/Linux_Agent.sh"
  }
  provisioner "remote-exec" {
    scripts = [
      "bin/centos7-docker-install.sh",
      "bin/vulhub-install.sh"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/Linux_Agent.sh",
      "sudo yum install selinux-policy-devel -y",
      "sudo /tmp/Linux_Agent.sh"
    ]
  }
}
*/
