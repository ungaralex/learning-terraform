terraform {
  backend "s3" {
    key            = "stage/data-stores/mysql/terraform.tfstate"
    bucket         = "terraform-alun-state"
    dynamodb_table = "terraform-locks"
    region         = "eu-central-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "webserver_data_store" {
  source                = "../../../modules/data-stores/mysql"
  stage                 = "stage"
  db_cluster_name       = "HelloWorldStage"
  bastion_key_pair_name = "NetlightMacbook"
}