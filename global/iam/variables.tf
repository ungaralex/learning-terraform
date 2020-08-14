variable "user_names" {
  description = "Creat IAM users with these names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}

variable "give_neo_cloudwatch_full_access" {
  description = "Give Neo full write access to cloudwatch"
  type        = bool
}