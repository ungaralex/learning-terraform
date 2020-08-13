data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "terraform-alun-state"
    key    = "${var.stage}/data-stores/mysql/terraform.tfstate"
    region = "eu-central-1"
  }
}

data "template_file" "hello_world_index" {
  template = file("${path.module}/user-data.sh")
  vars = {
    server_port = var.server_http_port
    db_address  = data.terraform_remote_state.db.outputs.webserver_db_address
    db_port     = data.terraform_remote_state.db.outputs.webserver_db_port
  }
}

resource "aws_security_group" "all_ssh" {
  name = "${var.cluster_name}AllSSH"
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "simple_webserver_alb" {
  name = "${var.cluster_name}WebserverALB"
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "all_egress" {
  name = "${var.cluster_name}AllEgress"
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "webserver" {
  name = "${var.cluster_name}Webserver"
  ingress {
    security_groups = [aws_security_group.simple_webserver_alb.id]
    from_port       = var.server_http_port
    protocol        = "tcp"
    to_port         = var.server_http_port
  }
  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"] # for updates
  }
}

resource "aws_launch_template" "hello_world" {
  image_id               = var.webserver_base_ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.webserver.id, aws_security_group.all_ssh.id]
  user_data              = base64encode(data.template_file.hello_world_index.rendered)
}

resource "aws_alb_target_group" "hello_world" {
  name     = var.cluster_name
  port     = var.server_http_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_group" "hello_world" {
  max_size            = 5
  min_size            = 2
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns   = [aws_alb_target_group.hello_world.arn]
  health_check_type   = "ELB"
  launch_template {
    version = "$Latest"
    id      = aws_launch_template.hello_world.id
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = var.cluster_name
  }
}

resource "aws_alb" "hello_world" {
  name            = var.cluster_name
  subnets         = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.all_egress.id, aws_security_group.simple_webserver_alb.id]
}

resource "aws_alb_listener" "hello_world_webserver_http" {
  load_balancer_arn = aws_alb.hello_world.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_alb_listener_rule" "hello_world_forward" {
  listener_arn = aws_alb_listener.hello_world_webserver_http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.hello_world.arn
  }
}