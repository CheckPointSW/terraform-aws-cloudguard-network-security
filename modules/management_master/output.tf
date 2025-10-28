output "Deployment" {
  value = "Finalizing configuration may take up to 20 minutes after deployment is finished."
}

output "management_instance_id" {
  value = module.launch_management_into_vpc.management_instance_id
}
output "management_instance_name" {
  value = module.launch_management_into_vpc.management_instance_name
}
output "management_instance_tags" {
  value = module.launch_management_into_vpc.management_instance_tags
}
output "management_public_ip" {
  value = module.launch_management_into_vpc.management_public_ip
}
output "management_url" {
  value = module.launch_management_into_vpc.management_url
}