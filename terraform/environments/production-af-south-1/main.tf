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

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
}

module "compute" {
  source = "../../modules/compute"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.networking.vpc_id

  public_subnet_ids = module.networking.public_subnet_ids

  application_subnet_ids = module.networking.application_subnet_ids

  instance_type     = var.compute_instance_type
  min_size          = 2
  desired_capacity  = 2
  max_size          = 6
  health_check_path = "/health"

  common_tags = var.common_tags
}
