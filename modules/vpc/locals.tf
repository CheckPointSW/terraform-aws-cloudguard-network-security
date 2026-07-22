locals {
  ipv6_enabled = var.ip_mode != "IPv4"
  ipv4_enabled = var.ip_mode != "IPv6"

  // AWS Partner Revenue Measurement (PRM) tag, added to revenue-generating resources.
  prm_tags = var.product_code != "" ? { "aws-apn-id" = "pc:${var.product_code}" } : {}

  // Tags applied to every VPC resource: customer-provided custom tags plus the PRM
  // tag. prm_tags is merged last so the revenue-attribution tag can't be overridden.
  all_tags = merge(var.custom_tags, local.prm_tags)
}