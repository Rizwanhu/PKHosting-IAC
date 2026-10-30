output "ipv4" {
  value = hcloud_server.web.ipv4_address
}

output "admin_user" {
  value = var.admin_user
}

output "ssh_command" {
  value = "ssh ${var.admin_user}@${hcloud_server.web.ipv4_address}"
}
