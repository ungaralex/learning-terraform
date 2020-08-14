terraform {
  backend "s3" {
    key            = "global/iam/terraform.tfstate"
    bucket         = "terraform-alun-state"
    dynamodb_table = "terraform-locks"
    region         = "eu-central-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_iam_user" "matrix_users" {
  for_each = toset(var.user_names)
  name     = each.value
}