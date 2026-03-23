terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "mongodb" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["mongodb-replica-node-*"]
  }
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf_key" {
  key_name   = "mongodb_cluster_key"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "tf_key" {
  content         = tls_private_key.rsa.private_key_pem
  filename        = "${path.module}/../ansible/mongodb_cluster_key.pem"
  file_permission = "0400"
}

resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb_replica_sg"
  description = "Allow SSH and MongoDB inbound traffic"

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MongoDB from anywhere"
    from_port   = 27017
    to_port     = 27017
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

resource "aws_instance" "mongodb_node" {
  count                  = 3
  ami                    = data.aws_ami.mongodb.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.tf_key.key_name
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]

  tags = {
    Name = "mongodb-node-${count.index + 1}"
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    instances = aws_instance.mongodb_node
  })
  filename = "${path.module}/../ansible/inventory.ini"
}
