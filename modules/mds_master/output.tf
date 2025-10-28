output "Deployment" {
  value = "Finalizing configuration may take up to 20 minutes after deployment is finished."
}

output "vpc_id" {
  value = module.launch_vpc.vpc_id
}
output "vpc_public_subnets_ids_list" {
  value = module.launch_vpc.public_subnets_ids_list
}
output "vpc_private_subnets_ids_list" {
  value = module.launch_vpc.private_subnets_ids_list
}
output "mds_instance_id" {
  value = module.launch_mds_into_vpc.mds_instance_id
}
output "mds_instance_name" {
  value = module.launch_mds_into_vpc.mds_instance_name
}
output "mds_instance_tags" {
  value = module.launch_mds_into_vpc.mds_instance_tags
}