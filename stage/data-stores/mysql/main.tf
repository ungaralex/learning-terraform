terraform {
  backend "s3" {
    key = "stage/data-stores/mysql/terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "stage/data-sotres/MySQL"
}

resource "aws_security_group" "webserver_db" {
  name        = "WebserverRDS"
  description = "Control access to the DB of the webserver"
  ingress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = [aws_security_group.db_bastion_host.id]
  }
  egress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    security_groups = [aws_security_group.db_bastion_host.id]
  }
}

resource "aws_db_instance" "webserver" {
  instance_class         = "db.t2.micro"
  engine                 = "mysql"
  allocated_storage      = 10
  identifier_prefix      = "webserver-hello-world"
  name                   = "HelloWorldWebserver"
  username               = "admin"
  password               = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)[var.webserver_db_secret_key]
  vpc_security_group_ids = [aws_security_group.webserver_db.id]
}

resource "aws_security_group" "db_bastion_host" {
  description = "Access to all RDS instances via SSH"
  name        = "RDSBastionHost"
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "db_bastion_host" {
  ami                    = "ami-0788405fbdf5f7765"
  instance_type          = "t2.micro"
  key_name               = var.bastion_key_pair_name
  vpc_security_group_ids = [aws_security_group.db_bastion_host.id]
}