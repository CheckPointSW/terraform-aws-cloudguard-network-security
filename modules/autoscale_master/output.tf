output "Deployment" {
  value = "Finalizing instances configuration may take up to 20 minutes after deployment is finished."
}
output "autoscale_autoscaling_group_name" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_name
}
output "autoscale_autoscaling_group_arn" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_arn
}
output "autoscale_autoscaling_group_availability_zones" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_availability_zones
}
output "autoscale_autoscaling_group_desired_capacity" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_desired_capacity
}
output "autoscale_autoscaling_group_min_size" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_min_size
}
output "autoscale_autoscaling_group_max_size" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_max_size
}
output "autoscale_autoscaling_group_load_balancers" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_load_balancers
}
output "autoscale_autoscaling_group_target_group_arns" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_target_group_arns
}
output "autoscale_autoscaling_group_subnets" {
  value = module.launch_autoscale_into_vpc.autoscale_autoscaling_group_subnets
}
output "autoscale_launch_template_id" {
  value = module.launch_autoscale_into_vpc.autoscale_launch_template_id
}

output "autoscale_security_group_id" {
  value = module.launch_autoscale_into_vpc.autoscale_security_group_id
}

output "autoscale_iam_role_name" {
  value = module.launch_autoscale_into_vpc.autoscale_iam_role_name
}

