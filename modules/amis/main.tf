locals {
  // Decode the fetched amis.yaml once; the three maps below are all read from it.
  amis_yaml_mappings = yamldecode(split("Resources", data.http.amis_yaml_http.response_body)[0]).Mappings

  amis_yaml_regionMap = local.amis_yaml_mappings.RegionMap
  amis_yaml_converterMap = local.amis_yaml_mappings.ConverterMap
  amis_yaml_productCodeMap = try(local.amis_yaml_mappings.ProductCodeMap, {})


  //  Variables example:
  //  version_license = "R81.10-PAYG-NGTX"
  //  RESULT:
  //  version_license_key = "R81.10-PAYG-NGTX-GW"

  //  version_license_value = "R8110PAYGNGTXGW"

  // R81.10 has no blink image and is not expected to get one, and blink
  // first-time config is certified for a Primary MDS only. A secondary MDS or
  // an MLM therefore takes the ISO management image too - there is no
  // non-blink MDS product to fall back to (Azure does the same, CGNSPC-4476).
  // This is the single condition the AMI key and is_blink both derive from;
  // the CloudFormation twin spells it UsesIsoMgmtImage.
  uses_iso_mgmt_image = element(split("-", var.version_license), 0) == "R81.10" || (var.chkp_type == "mds" && !var.primary_mds)
  mgmt_suffix         = local.uses_iso_mgmt_image ? "-MGMT" : "-MGMT-BLINK"
  mds_suffix          = local.uses_iso_mgmt_image ? "-MGMT" : "-MDS-BLINK"

  version_license_key_mgmt_gw = format("%s%s", var.version_license, var.chkp_type == "gateway" ? "-GW" : var.chkp_type == "management" ? local.mgmt_suffix : var.chkp_type == "mds" ? local.mds_suffix : "")
  version_license_key = var.chkp_type == "standalone" ? format("%s%s", var.version_license, element(split("-", var.version_license), 1) == "BYOL" ? "-MGMT" : "") : local.version_license_key_mgmt_gw

  version_license_value = local.amis_yaml_converterMap[local.version_license_key]["Value"]

  //  Variables example:
  //  region = "us-east-1"
  //  version_license_key - see above
  //  RESULT: local.ami_id = "ami-1234567"
  //  When var.custom_ami is set, it takes precedence over the amis.yaml lookup so
  //  staging / candidate images can be deployed before publication.
  ami_id = var.custom_ami != "" ? var.custom_ami : local.amis_yaml_regionMap[local.region][local.version_license_value]

  // --- AWS Partner Revenue Measurement (PRM) ---
  // Consuming modules tag revenue-generating resources with
  // "aws-apn-id = pc:<product_code>" so AWS can attribute consumption to Check
  // Point. Both mappings come from the amis.yaml already fetched above, through
  // the same chain the CloudFormation templates use:
  //   !FindInMap [ProductCodeMap, !FindInMap [ConverterMap, Version, License], Value]
  // so the Terraform and CFT paths cannot report different codes for one product.
  // One code per license/role bucket, version-independent.
  //
  // try() rather than a hard index: a missing ConverterMap License or
  // ProductCodeMap entry yields no PRM tag instead of failing the plan of a live
  // deployment. check_prm_version_coverage.py asserts upstream coverage at MR
  // time, so "" should be unreachable in practice.
  product_code = try(local.amis_yaml_productCodeMap[local.amis_yaml_converterMap[local.version_license_key]["License"]]["Value"], "")
}