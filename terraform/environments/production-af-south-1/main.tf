module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr = "10.0.0.0/16"

  availability_zones = [
    "af-south-1a",
    "af-south-1b"
  ]

  public_subnet_cidrs = [
    "10.0.0.0/20",
    "10.0.16.0/20"
  ]

  private_app_subnet_cidrs = [
    "10.0.48.0/20",
    "10.0.64.0/20"
  ]

  private_db_subnet_cidrs = [
    "10.0.96.0/20",
    "10.0.112.0/20"
  ]

  enable_vpc_flow_logs = true
}
