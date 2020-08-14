terraform {
  backend "s3" {
    key            = "prod/services/webserver-cluster/terraform.tfstate"
    bucket         = "terraform-alun-state"
    dynamodb_table = "terraform-locks"
    region         = "eu-central-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "webserver_cluster" {
  source        = "../../../modules/services/webserver-cluster"
  cluster_name  = "HelloWorldProd"
  stage         = "prod"
  instance_type = "t2.micro"
  min_size      = 3
  max_size      = 5
}

resource "aws_autoscaling_schedule" "scale_out_during_busines_hours" {
  autoscaling_group_name = module.webserver_cluster.asg_name
  scheduled_action_name  = "ScaleOutDuringBusinessHours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 4
  recurrence             = "0 9 * * *"
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  autoscaling_group_name = module.webserver_cluster.asg_name
  scheduled_action_name  = "scale-in-at-night"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
}