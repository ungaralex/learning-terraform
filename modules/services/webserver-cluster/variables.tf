variable "webserver_base_ami" {
  description = "The base AMI to be used for creating the webserver"
  type        = string
  default     = "ami-0c115dbd34c69a004"
}

variable "server_http_port" {
  description = "The port of the webserver to accept HTTP requests"
  type        = number
  default     = 80
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "stage" {
  description = "The stage to be deployed to"
  type        = string
}