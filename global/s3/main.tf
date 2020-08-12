provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "terraform-alun-state"

  # prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  # enable versioning in order to see all changes to our state
  versioning {
    enabled = true
  }

  # enable encryption by default (i.e. to protect stored secrets)
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  hash_key     = "LockID"
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}