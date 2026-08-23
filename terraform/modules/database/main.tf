# modules/database/main.tf

resource "aws_rds_global_cluster" "archvault_global" {
  global_cluster_identifier = "archvault-global-cluster"
  engine                    = "aurora-postgresql"
  engine_version            = "15.3"
  storage_encrypted         = true
}

resource "aws_rds_cluster" "primary" {
  provider                  = aws.primary # af-south-1
  engine                    = aws_rds_global_cluster.archvault_global.engine
  cluster_identifier        = "archvault-primary-cluster"
  global_cluster_identifier = aws_rds_global_cluster.archvault_global.id
  kms_key_id                = var.primary_kms_key_arn
}

resource "aws_rds_cluster_instance" "primary_instances" {
  provider             = aws.primary
  count                = 3 # 1 Writer, 2 Readers across 3 AZs
  identifier           = "archvault-primary-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.primary.id
  instance_class       = "db.r6g.large"
  engine               = aws_rds_cluster.primary.engine
}
