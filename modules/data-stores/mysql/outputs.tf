output "webserver_db_address" {
  value = aws_db_instance.webserver.address
}

output "webserver_db_port" {
  value = aws_db_instance.webserver.port
}