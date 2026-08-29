# modules/database/secondary.tf

provider "aws" {
  alias  = "dr"
  region = "eu-west-1"
}

resource "aws_rds_cluster" "secondary" {
  provider                  = aws.dr
  engine                    = aws_rds_global_cluster.archvault_global.engine
  engine_version            = "15.3"
  cluster_identifier        = "archvault-dr-cluster"
  global_cluster_identifier = aws_rds_global_cluster.archvault_global.id
  kms_key_id                = var.secondary_kms_key_arn

  depends_on = [aws_rds_cluster.primary]
}

resource "aws_rds_cluster_instance" "secondary_instance" {
  provider           = aws.dr
  count              = 1 # Minimal skeleton for Pilot Light DR
  identifier         = "archvault-dr-instance-0"
  cluster_identifier = aws_rds_cluster.secondary.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.secondary.engine
}
