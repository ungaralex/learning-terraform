output "matrix_user_arns" {
  value = values(aws_iam_user.matrix_users)[*].arn
}