output "ami_id" {
  value = module.amis.ami_id
}
output "permissive_sg_id" {
  value = module.common_permissive_sg.permissive_sg_id
}
output "permissive_sg_name" {
  value = module.common_permissive_sg.permissive_sg_name
}
output "gateway_url" {
  value = length(module.common_eip.gateway_eip_public_ip) > 0 ? format("https://%s", module.common_eip.gateway_eip_public_ip[0]) : "Public IP not available"
}
output "gateway_url_ipv6" {
  value = length(aws_network_interface.public_eni.ipv6_addresses) > 0 ? format("https://[%s]", tolist(aws_network_interface.public_eni.ipv6_addresses)[0]) : "IPv6 address not available"
}
output "gateway_public_ip" {
  value = !local.ipv4_enabled ? null : module.common_eip.gateway_eip_public_ip
}
output "gateway_public_ipv6" {
  value = local.ipv6_enabled ? one(aws_network_interface.public_eni.ipv6_addresses) : null
}
output "gateway_instance_id" {
  value = module.common_gateway_instance.gateway_instance_id
}
output "gateway_instance_name" {
  value = module.common_gateway_instance.gateway_instance_name
}