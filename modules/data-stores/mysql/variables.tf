variable "bastion_key_pair_name" {
  description = "The name of the key pair for logging into EC2"
  type        = string
}

variable "webserver_db_secret_key" {
  description = "The key of the DB password in the AWS secrets manager"
  type        = string
  default     = "webserver-hello-world"
}

variable "db_cluster_name" {
  description = "The name of the deployed DB cluster"
  type        = string
}

variable "stage" {
  description = "The stage to be deployed on"
  type        = string
}
