locals {
  http_port    = 80
  https_port   = 443
  ssh_port     = 22
  all_ports    = 0
  instance_ami = "ami-0c115dbd34c69a004"
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

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
    server_port = local.http_port
    db_address  = data.terraform_remote_state.db.outputs.webserver_db_address
    db_port     = data.terraform_remote_state.db.outputs.webserver_db_port
  }
}

resource "aws_security_group" "all_ssh" {
  name = "${var.cluster_name}AllSSH"
  ingress {
    from_port   = local.ssh_port
    protocol    = local.tcp_protocol
    to_port     = local.ssh_port
    cidr_blocks = local.all_ips
  }
}

resource "aws_security_group" "simple_webserver_alb" {
  name = "${var.cluster_name}WebserverALB"
  ingress {
    from_port   = local.http_port
    protocol    = local.tcp_protocol
    to_port     = local.http_port
    cidr_blocks = local.all_ips
  }
  ingress {
    from_port   = local.https_port
    protocol    = local.tcp_protocol
    to_port     = local.https_port
    cidr_blocks = local.all_ips
  }
}

resource "aws_security_group" "all_egress" {
  name = "${var.cluster_name}AllEgress"
  egress {
    from_port   = local.all_ports
    protocol    = local.any_protocol
    to_port     = local.all_ports
    cidr_blocks = local.all_ips
  }
}

resource "aws_security_group" "webserver" {
  name = "${var.cluster_name}Webserver"
  ingress {
    security_groups = [aws_security_group.simple_webserver_alb.id]
    from_port       = local.http_port
    protocol        = local.tcp_protocol
    to_port         = local.http_port
  }
  egress {
    from_port   = local.all_ports
    protocol    = local.any_protocol
    to_port     = local.all_ports
    cidr_blocks = local.all_ips # for updates
  }
}

resource "aws_launch_template" "hello_world" {
  image_id               = local.instance_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.webserver.id, aws_security_group.all_ssh.id]
  user_data              = base64encode(data.template_file.hello_world_index.rendered)
}

resource "aws_alb_target_group" "hello_world" {
  name     = var.cluster_name
  port     = local.http_port
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
  max_size            = var.max_size
  min_size            = var.min_size
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
  dynamic "tag" {
    for_each = var.custom_instance_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_alb" "hello_world" {
  name            = var.cluster_name
  subnets         = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.all_egress.id, aws_security_group.simple_webserver_alb.id]
}

resource "aws_alb_listener" "hello_world_webserver_http" {
  load_balancer_arn = aws_alb.hello_world.arn
  port              = local.http_port
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

resource "aws_autoscaling_schedule" "scale_out_during_busines_hours" {
  count                  = var.use_day_night_scaling ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.hello_world.name
  scheduled_action_name  = "ScaleOutDuringBusinessHours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 4
  recurrence             = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count                  = var.use_day_night_scaling ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.hello_world.name
  scheduled_action_name  = "ScaleInAtNight"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "${var.cluster_name}HighCPUUtilization"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 90
  unit                = "Percent"
  dimensions = {
    AutoscalingGroupName = aws_autoscaling_group.hello_world.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  count               = format("%.1s", var.instance_type) == "t" ? 1 : 0
  alarm_name          = "${var.cluster_name}LowCPUCreditBalance"
  namespace           = "AWS/EC2"
  metric_name         = "CPUCreditBalance"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Minimum"
  threshold           = 10
  unit                = "Count"
}