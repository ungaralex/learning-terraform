output "s3_bucket_arn" {
  value = aws_s3_bucket.tfstate.arn
}

output "dynamo_db_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}