output "Deployment" {
  value = "Finalizing configuration may take up to 20 minutes after deployment is finished."
}
output "vpc_id" {
  value = module.launch_vpc.vpc_id
}
output "vpc_public_subnets_ids_list" {
  value = module.launch_vpc.public_subnets_ids_list
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
output "management_public_ipv6" {
  value = module.launch_management_into_vpc.management_public_ipv6
}
output "management_url" {
  value = module.launch_management_into_vpc.management_url
}
output "management_url_ipv6" {
  value = module.launch_management_into_vpc.management_url_ipv6
}