output "Deployment" {
  value = "Finalizing instances configuration may take up to 20 minutes after deployment is finished."
}
output "management_public_ip" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].management_public_ip
}
output "gwlb_arn" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].gwlb_arn
}
output "gwlb_service_name" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].gwlb_service_name
}
output "gwlb_name" {
  value = local.gateway_load_balancer_name
}
output "controller_name" {
  value = "gwlb-controller"
}
output "template_name" {
  value = var.configuration_template
}
output "ip_mode"{
  value = var.ip_mode
}
output "vpc_id" {
  value = module.launch_vpc.vpc_id

  precondition {
    condition     = var.create_asg_per_az || length(var.az_instance_types) == 0
    error_message = "az_instance_types requires create_asg_per_az=true. Otherwise, leave the map empty and use gateway_instance_type."
  }
  precondition {
    condition     = alltrue([for key in keys(var.az_instance_types) : contains(keys(var.public_subnets_map), key)])
    error_message = "Each az_instance_types key must also be a key in public_subnets_map."
  }
}
output "vpc_cidr_block" {
  value = module.launch_vpc.vpc_cidr_block
}
output "vpc_ipv6_cidr_block" {
  value = module.launch_vpc.vpc_ipv6_cidr_block
}
output "public_subnets_ids_map" {
  value = module.launch_vpc.public_subnets_ids_map
}
output "public_subnets_cidrs_map" {
  value = module.launch_vpc.public_subnets_cidrs_map
}
output "public_subnets_ipv6_cidrs_map" {
  value = module.launch_vpc.public_subnets_ipv6_cidrs_map
}
output "aws_igw" {
  value = module.launch_vpc.aws_igw
}
output "endpoint_service_id" {
  value = module.gwlb.endpoint_service_id
}
output "autoscale_asg_names" {
  value = module.gwlb.autoscale_asg_names
}

output "gateway_iam_role_name" {
  description = "Created gateway IAM role name, or null when gateway IAM creation is disabled. The caller can attach additional policies to this role."
  value       = module.gwlb.gateway_iam_role_name
}

output "gateway_iam_instance_profile_name" {
  description = "Gateway instance-profile name, supplied or created, or null when neither is configured."
  value       = module.gwlb.gateway_iam_instance_profile_name
}
