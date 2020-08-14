output "hello_world_alb_dns_name" {
  value = aws_alb.hello_world.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.hello_world.name
}