variable "user_names" {
  description = "Creat IAM users with these names"
  type        = list(string)
  default     = ["neo", "trinity", "morpheus"]
}