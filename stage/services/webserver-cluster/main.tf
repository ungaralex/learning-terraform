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
  source                = "../../../modules/services/webserver-cluster"
  cluster_name          = "HelloWorldStage"
  stage                 = "stage"
  instance_type         = "t2.micro"
  min_size              = 2
  max_size              = 5
  use_day_night_scaling = false
}