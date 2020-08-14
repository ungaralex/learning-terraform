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

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  count  = var.give_neo_cloudwatch_full_access ? 1 : 0
  name   = "cloudwatch-full-access"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

resource "aws_iam_policy" "cloudwatch_read_only" {
  count  = var.give_neo_cloudwatch_full_access ? 0 : 1
  name   = "CloudwatchReadOnly"
  policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

resource "aws_iam_user" "matrix_users" {
  for_each = toset(var.user_names)
  name     = each.value
}