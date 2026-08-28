provider "aws" {
  shared_credentials_files = ["/home/digitalist/.aws/credentials"]
  region                   = var.primary_region
}
