output "ami_id" {
  value = local.ami_id
}
output "version_license_with_suffix" {
  value = local.version_license_key
}
output "product_code" {
  description = "AWS Marketplace product code for PRM resource tagging (aws-apn-id = pc:<product_code>)"
  value = local.product_code
}