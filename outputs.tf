output "public_ip" {
  value       = module.ec2.public_ip
  description = "Public IPv4 of the EC2 instance"
}

output "ssh_command" {
  value       = "ssh -i <PATH_TO_PEM> ec2-user@${module.ec2.public_ip}"
  description = "SSH command (replace <PATH_TO_PEM> with your local .pem path)"
}

output "security_group_id" {
  value       = module.ec2.security_group_id
  description = "Security group ID used by the instance"
}

output "cluster_endpoint" {
  description = "Writer endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint for the Aurora cluster"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "db_name" {
  description = "Database name"
  value       = aws_rds_cluster.aurora.database_name
}

output "aurora_security_group_ids" {
  description = "Aurora security group IDs"
  value       = [aws_security_group.aurora.id]
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.aurora.name
}

output "kms_key_arn" {
  description = "KMS key ARN used for Aurora encryption"
  value       = local.aurora_kms_key_arn
}

output "vpc_id" {
  description = "VPC ID created by the networking module"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs created by the networking module"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs created by the networking module"
  value       = module.networking.public_subnet_ids
}

