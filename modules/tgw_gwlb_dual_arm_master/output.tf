output "Deployment" {
  value = "Finalizing instances configuration may take up to 20 minutes after deployment is finished."
}
output "management_public_ip" {
  depends_on = [module.tgw_gwlb]
  value = module.tgw_gwlb[*].management_public_ip
}
output "gwlb_arn" {
  depends_on = [module.tgw_gwlb]
  value = module.tgw_gwlb[*].gwlb_arn
}
output "management_subnet_id" {
  value = module.tgw_gwlb.management_subnet_id
}
output "gwlb_service_name" {
  depends_on = [module.tgw_gwlb]
  value = module.tgw_gwlb[*].gwlb_service_name
}
output "gwlb_name" {
  value = module.tgw_gwlb[*].gwlb_name
}
output "controller_name" {
  value = "gwlb-controller"
}
output "template_name" {
  value = var.configuration_template
}