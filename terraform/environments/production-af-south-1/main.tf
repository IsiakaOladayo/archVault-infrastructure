module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs

  common_tags = var.common_tags
}

module "security" {
  source = "../../modules/security"

  providers = {
    aws.primary = aws
    aws.dr      = aws.dr
  }

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id

  common_tags = var.common_tags
}

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

  documents_kms_key_primary_arn = module.kms.documents_kms_key_primary_arn
  documents_kms_key_dr_arn      = module.kms.documents_kms_key_dr_arn

  common_tags = var.common_tags
}

module "compute" {
  source = "../../modules/compute"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.networking.vpc_id

  public_subnet_ids = module.networking.public_subnet_ids

  private_app_subnet_ids = module.networking.private_app_subnet_ids

  alb_security_group_id = module.security.alb_security_group_id

  application_security_group_id = module.security.application_security_group_id

  container_image = var.container_image

  container_port = var.container_port

  app_port = var.app_port

  desired_count = var.ecs_desired_count

  certificate_arn = var.certificate_arn

  waf_web_acl_arn = module.security.regional_waf_web_acl_arn

  common_tags = var.common_tags
}

module "cache" {
  source = "../../modules/cache"

  project_name = var.project_name
  environment  = var.environment

  vpc_id = module.networking.vpc_id

  private_app_subnet_ids = module.networking.private_app_subnet_ids

  redis_security_group_id = module.security.redis_security_group_id

  redis_node_type = var.redis_node_type

  redis_engine_version = var.redis_engine_version

  redis_num_cache_nodes = var.redis_num_cache_nodes

  automatic_failover_enabled = var.redis_automatic_failover_enabled

  multi_az_enabled = var.redis_multi_az_enabled

  kms_key_id = module.kms.database_kms_key_arn

  common_tags = var.common_tags
}

module "database" {
  source = "../../modules/database"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  project_name = var.project_name
  environment  = var.environment

  vpc_id                     = module.networking.vpc_id
  private_db_subnet_ids      = module.networking.private_db_subnet_ids
  database_security_group_id = module.security.database_security_group_id

  database_kms_key_arn = module.kms.database_kms_key_arn
  secrets_kms_key_arn  = module.kms.secrets_kms_key_arn

  dr_private_db_subnet_ids      = module.networking.dr_private_db_subnet_ids
  dr_database_security_group_id = module.security.dr_database_security_group_id
  secondary_kms_key_arn         = module.kms.database_kms_key_dr_arn

  common_tags = var.common_tags
}

module "kms" {
  source = "../../modules/kms"

  providers = {
    aws.primary = aws.primary
    aws.dr      = aws.dr
  }

  project_name = var.project_name
  environment  = var.environment

  common_tags = var.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment

  ecs_cluster_name = module.compute.ecs_cluster_id
  ecs_service_name = module.compute.ecs_service_name
  alb_arn_suffix   = module.compute.alb_arn_suffix

  log_group_name = module.compute.cloudwatch_log_group_name

  database_cluster_id = module.database.primary_cluster_id

  rds_proxy_name             = module.database.rds_proxy_name
  rds_proxy_max_connections  = var.rds_proxy_max_connections

  elasticache_replication_group_id = module.cache.redis_replication_group_id

  alarm_email = var.alarm_email

  common_tags = var.common_tags
}

variable "rds_proxy_max_connections" {
  description = "Max connections on the RDS Proxy target group for this environment"
  type        = number
}

variable "alarm_email" {
  description = "Email address to subscribe to the monitoring alarm SNS topic"
  type        = string
  default     = null
}
