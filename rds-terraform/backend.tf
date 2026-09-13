terraform {
  required_version = ">= 1.5"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
  backend "s3" {
    bucket         = "fda-tfstate-654654477638"
    key            = "rds/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fda-tflock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
