output "Deployment" {
  value = "Finalizing configuration may take up to 20 minutes after deployment is finished."
}

output "mds_instance_id" {
  value = aws_instance.mds-instance.id
}
output "mds_instance_name" {
  value = aws_instance.mds-instance.tags["Name"]
}
output "mds_instance_tags" {
  value = aws_instance.mds-instance.tags
}
output "mds_secondary_private_ips" {
  value = local.mds_secondary_private_ips
}
output "mds_secondary_public_ips" {
  value = aws_eip.mds_secondary_eip[*].public_ip
}