module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr = var.vpc_cidr

  availability_zones = var.availability_zones

  public_subnet_cidrs = var.public_subnet_cidrs

  private_app_subnet_cidrs = var.private_app_subnet_cidrs

  private_db_subnet_cidrs = var.private_db_subnet_cidrs

  enable_nat_gateway = true

  common_tags = var.common_tags
}

#security modules import
module "security" {
  source = "../../modules/security"

  providers = {
    aws.primary = aws
    aws.dr      = aws.dr
  }

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.networking.vpc_id

  ecs_container_port = 3000

  database_port = 5432

  redis_port = 6379

  enable_waf = true

  common_tags = var.common_tags
}


#storage module import
module "storage" {
  source = "../../modules/storage"

  providers = {
    aws.primary = aws
    aws.replica = aws.dr
  }

  project_name = var.project_name
  environment  = var.environment

  primary_region = var.primary_region
  replica_region = var.dr_region

  documents_kms_key_primary_arn = module.security.documents_kms_key_primary_arn
  documents_kms_key_dr_arn      = module.security.documents_kms_key_dr_arn

  common_tags = var.common_tags
}
