############################
# Networking: Subnet Group
############################

# this creates a subnet group for the Aurora cluster in the private subnets

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.name_prefix}-aurora-subnet-group"
  subnet_ids = module.networking.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-subnet-group"
  })
}

############################
# Security Group: Aurora
# - inbound 5432 ONLY from EC2 SG
############################

resource "aws_security_group" "aurora" {
  name        = "${var.name_prefix}-aurora-sg"
  description = "Aurora SG: allow PostgreSQL only from EC2 SG"
  vpc_id      = module.networking.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "aurora_from_ec2_5432" {
  security_group_id            = aws_security_group.aurora.id
  referenced_security_group_id = module.ec2.security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from EC2 SG only"
}

# Outbound: allow the cluster to talk out (DNS, AWS APIs, etc.)
resource "aws_vpc_security_group_egress_rule" "aurora_all_egress" {
  security_group_id = aws_security_group.aurora.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

############################
# Optional KMS CMK
############################

resource "aws_kms_key" "aurora" {
  count                   = var.manage_kms_key ? 1 : 0
  description             = "CMK for ${var.name_prefix} Aurora encryption"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-kms"
  })
}
# aws_kms_key creates a Customer-Managed Key (CMK) (AWS now just calls it a KMS key)

resource "aws_kms_alias" "aurora" {
  count         = var.manage_kms_key ? 1 : 0
  name          = "alias/${var.name_prefix}-aurora"
  target_key_id = aws_kms_key.aurora[0].key_id
}
# aws_kms_alias creates a stable, human-readable name that points to a customer-managed KMS key, making rotation and management safer and easier


# This local evaluates the logic for choosing which KMS key ARN to use—either a Terraform-managed CMK or an existing one—and stores the result so it can be reused as local.aurora_kms_key_arn.
locals {
  aurora_kms_key_arn = var.manage_kms_key ? aws_kms_key.aurora[0].arn : var.kms_key_arn
}

############################
# Aurora Cluster (Serverless v2)
############################

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.name_prefix}-aurora-cluster"

  engine         = "aurora-postgresql"
  engine_version = var.engine_version

  database_name   = var.db_name
  master_username = var.master_username
  master_password = var.master_password

  # Serverless v2 uses engine_mode = "provisioned" + serverlessv2 scaling block
  engine_mode = "provisioned"
# Aurora Serverless v2 runs on the provisioned engine; serverless behaviour is enabled through ACU scaling and db.serverless, not the engine mode.

  serverlessv2_scaling_configuration {
    min_capacity = var.serverlessv2_min_acu
    max_capacity = var.serverlessv2_max_acu
  }

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  storage_encrypted = true
# I always enable storage_encrypted = true because encryption at rest is a baseline security control and cannot be enabled after creation.”

  kms_key_id        = local.aurora_kms_key_arn

  deletion_protection = var.deletion_protection
# set to false for labs to allow easy deletion

  # Cost/safety controls for labs:
  skip_final_snapshot       = var.skip_final_snapshot
#   means “When I destroy this cluster, delete it immediately.”
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-final-${replace(timestamp(), "[: TZ-]", "")}"
# AWS requires: If skip_final_snapshot = false, You must provide a snapshot name

# If we are skipping the snapshot → don’t provide a name, Otherwise → generate a unique snapshot name

# Terraform requirement: You cannot give a snapshot identifier if you’re skipping snapshots, So we explicitly set it to null

# final snapshot example name: lab-aurora-mig-final-20260116094231

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-cluster"
  })
}

############################
# Cluster Instance (Serverless v2)
############################

resource "aws_rds_cluster_instance" "aurora" {
  identifier         = "${var.name_prefix}-aurora-instance-1"
  cluster_identifier = aws_rds_cluster.aurora.id

  engine         = aws_rds_cluster.aurora.engine
  engine_version = aws_rds_cluster.aurora.engine_version

  instance_class = "db.serverless"
# This tells AWS that this Aurora cluster instance does NOT have a fixed size and should scale using Serverless v2 (ACUs).

  publicly_accessible = false
# this means The database will NOT get a public IP address and cannot be reached from the public internet.
# Setting publicly_accessible = false ensures the database has no public IP and is only reachable from within the VPC, enforcing network-level isolation.
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-aurora-instance-1"
  })
}
