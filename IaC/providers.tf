terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.32.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_token
}

provider "aws" {
  region = var.aws_region
}

