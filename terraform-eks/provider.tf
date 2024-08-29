terraform {
  required_providers {
    aws = {
      source         = "hashicorp/aws"
      version        = "~>4.19.0"
    }
  }

  backend "s3" {
    bucket           = "blueray254"
    key              = "qr-code-key"
    region           = "eu-west-1"
    dynamodb_table   = "TerraformStateLock"
  }
}

provider "aws" {
  # Configuration options
  region             = var.region
}