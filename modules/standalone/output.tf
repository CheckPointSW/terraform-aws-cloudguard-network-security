output "standalone_instance_id" {
  value = aws_instance.standalone-instance.id
}
output "standalone_instance_name" {
  value = aws_instance.standalone-instance.tags["Name"]
}
output "standalone_public_ip" {
  value = aws_instance.standalone-instance.public_ip
}
output "standalone_public_ipv6" {
  value = local.ipv6_enabled ? one(aws_network_interface.public_eni.ipv6_addresses) : null
}
output "standalone_ssh" {
  value = format("ssh -i %s admin@%s", var.key_name, aws_instance.standalone-instance.public_ip)
}
output "standalone_ssh_ipv6" {
  value = local.ipv6_enabled ? format("ssh -i %s admin@%s", var.key_name, one(aws_network_interface.public_eni.ipv6_addresses)) : "IPv6 address not available"
}
output "standalone_url" {
  value = format("https://%s", aws_instance.standalone-instance.public_ip)
}
output "standalone_url_ipv6" {
  value = local.ipv6_enabled ? format("https://[%s]", one(aws_network_interface.public_eni.ipv6_addresses)) : "IPv6 address not available"
}