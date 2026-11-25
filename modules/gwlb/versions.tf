terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100.0"
    }
    http = {
      version = "~> 3.4.0"
    }
    random = {
      version = "~> 3.5.1"
    }
  }
}
