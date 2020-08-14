output "alb_dns_name" {
  value = module.webserver_cluster.hello_world_alb_dns_name
}

output "upper_heroes" {
  value = { for name, role in var.matrix_heroes : upper(name) => upper(role) if length(name) > 3 }
}

output "for_directive_strip_marker" {
  value = <<EOF
%{~for name in values(var.matrix_heroes)}
${name}
%{~endfor}
EOF
}