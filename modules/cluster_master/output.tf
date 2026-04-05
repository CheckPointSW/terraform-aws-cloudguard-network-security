output "ami_id" {
  value = module.launch_cluster_into_vpc.ami_id
}
output "availability_zone" {
  value = module.launch_cluster_into_vpc.availability_zone
  description = "The availability zone where the cluster is deployed"
}
output "zone_type" {
  value = module.launch_cluster_into_vpc.zone_type
  description = "The type of zone (availability-zone or local-zone)"
}
output "network_border_group" {
  value = module.launch_cluster_into_vpc.network_border_group
  description = "The network border group for the zone"
}
output "cluster_public_ip" {
  value = var.allocate_and_associate_eip ? module.launch_cluster_into_vpc.cluster_public_ip : []
}
output "member_a_public_ip" {
  value = module.launch_cluster_into_vpc.member_a_public_ip
}
output "member_b_public_ip" {
  value = module.launch_cluster_into_vpc.member_b_public_ip
}
output "member_a_ssh" {
  value = module.launch_cluster_into_vpc.member_a_ssh
}
output "member_b_ssh" {
  value = module.launch_cluster_into_vpc.member_b_ssh
}
output "member_a_url" {
  value = module.launch_cluster_into_vpc.member_a_url
}
output "member_b_url" {
  value = module.launch_cluster_into_vpc.member_b_url
}