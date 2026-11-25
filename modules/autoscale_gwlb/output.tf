output "Deployment" {
  value = "Finalizing instances configuration may take up to 20 minutes after deployment is finished."
}

output "autoscale_autoscaling_group_name" {
  value = one(aws_autoscaling_group.asg[*].name)
}
output "autoscale_autoscaling_group_arn" {
  value = one(aws_autoscaling_group.asg[*].arn)
}
output "autoscale_autoscaling_group_availability_zones" {
  value = one(aws_autoscaling_group.asg[*].availability_zones)
}
output "autoscale_autoscaling_group_desired_capacity" {
  value = one(aws_autoscaling_group.asg[*].desired_capacity)
}
output "autoscale_autoscaling_group_min_size" {
  value = one(aws_autoscaling_group.asg[*].min_size)
}
output "autoscale_autoscaling_group_max_size" {
  value = one(aws_autoscaling_group.asg[*].max_size)
}
output "autoscale_autoscaling_group_target_group_arns" {
  value = one(aws_autoscaling_group.asg[*].target_group_arns)
}
output "autoscale_autoscaling_group_subnets" {
  value = one(aws_autoscaling_group.asg[*].vpc_zone_identifier)
}

output "autoscale_asg_names" {
  description = "Map of az_instance_types key => Auto Scaling Group name. Empty unless az_instance_types is set."
  value       = { for key, asg in aws_autoscaling_group.az : key => asg.name }
}

output "autoscale_launch_template_id" {
  value = aws_launch_template.asg_launch_template.id
}

output "autoscale_security_group_id" {
  description = "First attached security group ID, or null if none is attached. Preserves the existing single-group output when a caller supplies several groups."
  value       = try(local.launch_template_security_group_ids[0], null)
}

output "autoscale_iam_role_name" {
  value = aws_iam_role.role.*.name
}

output "ip_mode"{
  value = var.ip_mode
}

output "gateway_iam_role_name" {
  description = "Created gateway IAM role name, or null when gateway IAM creation is disabled. The caller can attach additional policies to this role."
  value       = one(aws_iam_role.role[*].name)
}

output "gateway_iam_instance_profile_name" {
  description = "Gateway instance-profile name, supplied or created, or null when neither is configured."
  value       = local.instance_profile_name
}
