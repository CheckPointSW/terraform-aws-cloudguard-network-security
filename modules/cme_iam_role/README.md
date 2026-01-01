# AWS IAM Role for Cloud Management Extension (CME) Terraform module

Terraform module which creates an AWS IAM Role for Cloud Management Extension (CME) on Security Management Server.

These types of Terraform resources are supported:
* [AWS IAM role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
* [AWS IAM policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
* [AWS IAM policy attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)

This type of Terraform data source is supported:
* [AWS IAM policy document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)

See the [Creating an AWS IAM Role for Security Management Server](https://supportcenter.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk122074) for additional information


## Usage
Follow best practices for using CGNS modules on [the root page](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest#:~:text=Best%20Practices%20for%20Using%20Our%20Modules).

**Example:**
```
provider "aws" {}

module "example_module" {

    source  = "CheckPointSW/cloudguard-network-security/aws//modules/cme_iam_role"
    version = "1.0.6"

    permissions = "Create with read permissions"
    sts_roles = ['arn:aws:iam::111111111111:role/role_name']
    trusted_account = ""
}
```
## Inputs
| Name            | Description                                                                                                                                                           | Type         | Allowed Values                                                                                                                                  |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| permissions     | The IAM role permissions                                                                                                                                              | string       | - Create with assume role permissions (specify an STS role ARN)<br>- Create with read permissions<br>- Create with read-write permissions<br>**Default:** Create with read permissions |
| sts_roles       | The IAM role will be able to assume these STS Roles (map of string ARNs)                                                                                              | list(string) |                                                                                                                                              |
| trusted_account | A 12-digit number that represents the ID of a trusted account. IAM users in this account will be able to assume the IAM role and receive the permissions attached to it | string       |                                                                                                                                              |


## Outputs
To display the outputs defined by the module, create an `outputs.tf` file with the following structure:
```
output "instance_public_ip" {
  value = module.{module_name}.instance_public_ip
}
```
| Name                 | Description                           |
|----------------------|---------------------------------------|
| cme_iam_role_arn     | The created AWS IAM Role arn          |
| cme_iam_role_name    | The created AWS IAM Role name         |
| cme_iam_profile_name | The created AWS instance profile name |
| cme_iam_profile_arn  | The created AWS instance profile arn  |