terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"

      configuration_aliases = [
        aws.primary,
        aws.dr,
        aws.us_east_1
      ]
    }
  }
}
