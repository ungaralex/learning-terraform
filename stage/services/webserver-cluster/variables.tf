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

variable "alb_name" {
  description = "The name of the webserver ALB"
  type        = string
  default     = "HelloWorldALB"
}

variable "webserver_target_group_name" {
  description = "The name of the webserver target group"
  type        = string
  default     = "HelloWorld"
}

variable "security_group_ssh_name" {
  description = "The name of the simple SSH security group"
  type        = string
  default     = "SimpleSSH"
}

variable "security_group_all_egress" {
  description = "The name of the all egress allowed security group"
  type        = string
  default     = "AllEgressAllowed"
}

variable "security_group_webserver" {
  description = "The name of the webserver security group"
  type        = string
  default     = "SimpleWebserver"
}

variable "security_group_webserver_from_alb" {
  description = "The name of the ingress security group from the ALB to the webserver"
  type        = string
  default     = "OnlyWebserverALB"
}