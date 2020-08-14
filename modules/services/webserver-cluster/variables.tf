variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "stage" {
  description = "The stage to be deployed to"
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 to instance to be used for the webserver"
  type        = string
}

variable "min_size" {
  description = "The minimum size the ASG should maintain"
  type        = number
}

variable "max_size" {
  description = "The maximum size the ASG should maintain"
  type        = number
}

variable "custom_instance_tags" {
  description = "Custom tags for the by the ASG generated instances"
  type        = map(string)
  default     = {}
}

variable "use_day_night_scaling" {
  description = "Whether the ASG should scale in/out during business hours"
  type        = bool
}