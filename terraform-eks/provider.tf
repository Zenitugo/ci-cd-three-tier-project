terraform {
  required_providers {
    aws = {
      source         = "hashicorp/aws"
      version        = "~>4.19.0"
    }
  }

  backend "s3" {
    bucket           = var.bucket-name
    key              = var.key-name
    region           = var.region
    dynamodb_table   = var.dynamodb_table
  }
}

provider "aws" {
  # Configuration options
  region             = var.region
}