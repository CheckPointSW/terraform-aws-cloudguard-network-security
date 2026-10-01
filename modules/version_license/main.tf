locals {
  gw_versions = [
    "R81.10-BYOL",
    "R81.10-PAYG-NGTP",
    "R81.10-PAYG-NGTX",
    "R81.20-BYOL",
	  "R81.20-PAYG-NGTP",
    "R81.20-PAYG-NGTX",
    "R82-BYOL",
	  "R82-PAYG-NGTP",
    "R82-PAYG-NGTX",
    "R82.10-BYOL",
	  "R82.10-PAYG-NGTP",
    "R82.10-PAYG-NGTX",
    "R82.20-BYOL",
    "R82.20-PAYG-NGTP",
    "R82.20-PAYG-NGTX"
  ]
  mgmt_versions = [
    "R81.10-BYOL",
    "R81.10-PAYG",
    "R81.20-BYOL",
    "R81.20-PAYG",
    "R82-BYOL",
    "R82-PAYG",
    "R82.10-BYOL",
    "R82.10-PAYG",
    "R82.20-BYOL",
    "R82.20-PAYG"
  ]
  mds_versions = [
    "R81.10-BYOL",
    "R81.20-BYOL",
    "R82-BYOL",
    "R82.10-BYOL",
    "R82.20-BYOL"
  ]
  standalone_versions = [
    "R81.10-BYOL",
    "R81.10-PAYG-NGTP",
    "R81.20-BYOL",
    "R81.20-PAYG-NGTP",
    "R82-BYOL",
    "R82-PAYG-NGTP",
    "R82.10-BYOL",
    "R82.10-PAYG-NGTP",
    "R82.20-BYOL",
    "R82.20-PAYG-NGTP"
  ]
  gwlb_gw_versions = [
	  "R81.20-BYOL",
	  "R81.20-PAYG-NGTP",
    "R81.20-PAYG-NGTX",
    "R82-BYOL",
	  "R82-PAYG-NGTP",
    "R82-PAYG-NGTX",
    "R82.10-BYOL",
	  "R82.10-PAYG-NGTP",
    "R82.10-PAYG-NGTX",
    "R82.20-BYOL",
    "R82.20-PAYG-NGTP",
    "R82.20-PAYG-NGTX"
    ]
  // The Quick Start (qs_autoscale) solution is supported up to R82 only.
  // R82.10 and above are intentionally absent - deploy the autoscale modules instead.
  qs_gw_versions = [
    "R81.10-BYOL",
    "R81.10-PAYG-NGTP",
    "R81.10-PAYG-NGTX",
    "R81.20-BYOL",
    "R81.20-PAYG-NGTP",
    "R81.20-PAYG-NGTX",
    "R82-BYOL",
    "R82-PAYG-NGTP",
    "R82-PAYG-NGTX"
  ]
  qs_mgmt_versions = [
    "R81.10-BYOL",
    "R81.10-PAYG",
    "R81.20-BYOL",
    "R81.20-PAYG",
    "R82-BYOL",
    "R82-PAYG"
  ]
}

locals {
  gw_values = var.chkp_type == "gateway" ? local.gw_versions : []
  mgmt_values = var.chkp_type == "management" ? local.mgmt_versions : []
  mds_values = var.chkp_type == "mds" ? local.mds_versions : []
  standalone_values = var.chkp_type == "standalone" ? local.standalone_versions : []
  gwlb_gw_values = var.chkp_type == "gwlb_gw" ? local.gwlb_gw_versions  : []
  qs_gw_values = var.chkp_type == "qs_gateway" ? local.qs_gw_versions : []
  qs_mgmt_values = var.chkp_type == "qs_management" ? local.qs_mgmt_versions : []
  allowed_values = coalescelist(local.gw_values, local.mgmt_values, local.standalone_values, local.mds_values, local.gwlb_gw_values, local.qs_gw_values, local.qs_mgmt_values)
  is_allowed_type = index(local.allowed_values, var.version_license)
}
