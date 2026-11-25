output "Deployment" {
  value = "Finalizing instances configuration may take up to 20 minutes after deployment is finished."
}
output "gwlb_arn" {
  value = module.gateway_load_balancer.load_balancer_arn
}
output "gwlb_service_name" {
  value = "com.amazonaws.vpce.${data.aws_region.current.name}.${aws_vpc_endpoint_service.gwlb_endpoint_service.id}"
}
output "management_public_ip" {
  depends_on = [module.management]
  value = module.management[*].management_public_ip
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

output "endpoint_service_id" {
  value = aws_vpc_endpoint_service.gwlb_endpoint_service.id
}
output "autoscale_asg_names" {
  value = module.autoscale_gwlb.autoscale_asg_names
}

output "gateway_iam_role_name" {
  description = "Created gateway IAM role name, or null when gateway IAM creation is disabled. The caller can attach additional policies to this role."
  value       = module.autoscale_gwlb.gateway_iam_role_name
}

output "gateway_iam_instance_profile_name" {
  description = "Gateway instance-profile name, supplied or created, or null when neither is configured."
  value       = module.autoscale_gwlb.gateway_iam_instance_profile_name
}
