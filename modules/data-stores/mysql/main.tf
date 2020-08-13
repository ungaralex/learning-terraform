data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "${var.stage}/data-stores/MySQL"
}

resource "aws_security_group" "webserver_db" {
  name        = "${var.db_cluster_name}WebserverRDS"
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
  identifier_prefix      = "${var.stage}-webserver-hello-world"
  name                   = "HelloWorldWebserver"
  username               = "admin"
  password               = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)[var.webserver_db_secret_key]
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.webserver_db.id]
}

resource "aws_security_group" "db_bastion_host" {
  description = "Access to all RDS instances via SSH"
  name        = "${var.db_cluster_name}RDSBastionHost"
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
  ami                    = "ami-0c115dbd34c69a004"
  instance_type          = "t2.micro"
  key_name               = var.bastion_key_pair_name
  vpc_security_group_ids = [aws_security_group.db_bastion_host.id]
  tags = {
    Name = "${var.db_cluster_name}RDSBastionHost"
  }
}