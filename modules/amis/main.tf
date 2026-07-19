locals {
  amis_yaml_regionMap = yamldecode(split("Resources", data.http.amis_yaml_http.response_body)[0]).Mappings.RegionMap
  amis_yaml_converterMap = yamldecode(split("Resources", data.http.amis_yaml_http.response_body)[0]).Mappings.ConverterMap


  //  Variables example:
  //  version_license = "R81.10-PAYG-NGTX"
  //  RESULT:
  //  version_license_key = "R81.10-PAYG-NGTX-GW"

  //  version_license_value = "R8110PAYGNGTXGW"

  version_license_key_mgmt_gw = format("%s%s", var.version_license, var.chkp_type == "gateway" ? "-GW" : var.chkp_type == "management" ? "-MGMT" : var.chkp_type == "mds" ? "-MGMT" : "")
  version_license_key = var.chkp_type == "standalone" ? format("%s%s", var.version_license, element(split("-", var.version_license), 1) == "BYOL" ? "-MGMT" : "") : local.version_license_key_mgmt_gw

  version_license_value = local.amis_yaml_converterMap[local.version_license_key]["Value"]

  //  Variables example:
  //  region = "us-east-1"
  //  version_license_key - see above
  //  RESULT: local.ami_id = "ami-1234567"
  ami_id = local.amis_yaml_regionMap[local.region][local.version_license_value]

  // --- AWS Partner Revenue Measurement (PRM) ---
  // Derive the license/role bucket from version_license + chkp_type and map it
  // to an AWS Marketplace product code. Consuming modules tag revenue-generating
  // resources with "aws-apn-id = pc:<product_code>" so AWS can attribute
  // consumption to Check Point. One product code per license/role bucket;
  // version-independent. Mirrors the ConverterMap.License + ProductCodeMap logic
  // shared with the CloudFormation templates.
  version_license_parts = split("-", var.version_license)
  prm_license           = length(local.version_license_parts) > 1 ? element(local.version_license_parts, 1) : "" // BYOL | PAYG
  prm_product           = length(local.version_license_parts) > 2 ? element(local.version_license_parts, 2) : "" // NGTP | NGTX | ""
  prm_is_mgmt           = contains(["management", "mds"], var.chkp_type)

  // license/role bucket: BYOLGW, BYOLMGMT, PAYGMGMT, PAYGNGTP, PAYGNGTPGW, PAYGNGTXGW.
  // A standalone is a combined management+gateway image: like the ConverterMap
  // key logic above it resolves to the management AMI for BYOL (-> BYOLMGMT) and
  // to the non-GW all-in-one product for PAYG-NGTP (-> PAYGNGTP).
  prm_bucket = (
    local.prm_is_mgmt ? (local.prm_license == "BYOL" ? "BYOLMGMT" : "PAYGMGMT") :
    var.chkp_type == "standalone" ? (local.prm_license == "BYOL" ? "BYOLMGMT" : "PAYGNGTP") :
    local.prm_license == "BYOL" ? "BYOLGW" :
    local.prm_product == "NGTX" ? "PAYGNGTXGW" : "PAYGNGTPGW"
  )

  // AWS Marketplace product codes for PRM resource tagging.
  product_codes = {
    BYOLGW     = "checkpoint_byol_5"
    BYOLMGMT   = "checkpoint_byol_4"
    PAYGMGMT   = "checkpoint_mgmt5_2"
    PAYGNGTP   = "checkpoint_ngtp_5"
    PAYGNGTPGW = "checkpoint_ngtp_3"
    PAYGNGTXGW = "checkpoint_ngtx_2"
  }

  // lookup() with a default avoids a hard plan-time error if an unexpected input
  // ever derives a bucket outside the map; check_prm_version_coverage.py remains
  // the source of truth that every permitted version maps to a product code.
  product_code = lookup(local.product_codes, local.prm_bucket, "")
}