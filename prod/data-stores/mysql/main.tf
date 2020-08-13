provider "aws" {
  region = "eu-central-1"
}

module "webserver_data_store" {
  source                = "../../../modules/data-stores/mysql"
  stage                 = "prod"
  db_cluster_name       = "HelloWorldProd"
  bastion_key_pair_name = "NetlightMacbook"
}