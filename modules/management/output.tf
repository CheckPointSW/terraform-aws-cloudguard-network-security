output "Deployment" {
  value = "Finalizing configuration may take up to 20 minutes after deployment is finished."
}

output "management_instance_id" {
  value = aws_instance.management-instance.id
}
output "management_instance_name" {
  value = aws_instance.management-instance.tags["Name"]
}
output "management_instance_tags" {
  value = aws_instance.management-instance.tags
}
output "management_public_ip" {
  value = aws_instance.management-instance.public_ip
}
output "management_public_ipv6" {
  value = local.ipv6_enabled ? one(aws_instance.management-instance.ipv6_addresses) : null
}
output "management_url" {
  value = format("https://%s", aws_instance.management-instance.public_ip)
}
output "management_url_ipv6" {
  value = local.ipv6_enabled ? format("https://[%s]", one(aws_instance.management-instance.ipv6_addresses)) : "IPv6 address not available"
}