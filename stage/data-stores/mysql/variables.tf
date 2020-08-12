variable "bastion_key_pair_name" {
  description = "The name of the key pair for loggin into EC2"
  type        = string
  default     = "NetlightMacbook"
}

variable "webserver_db_secret_key" {
  description = "The key of the DB password in the AWS secrets manager"
  type        = string
  default     = "webserver-hello-world"
}