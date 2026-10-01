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
output "is_blink" {
  description = "True iff the resolved image is a blink build - the exact inverse of the AMI choice, so the two cannot drift apart"
  value = !local.uses_iso_mgmt_image
}
