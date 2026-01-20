variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
  default     = "lab-ec2-docker-postgres"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Existing EC2 key pair name in AWS (e.g. labec2)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR format, e.g. 81.2.69.142/32"
  type        = string
}

variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources"
  default     = "lab-aurora-mig"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default = {
    Project = "lab-aurora-mig"
    Owner   = "suleyman"
    TTL     = "24h"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs (2 recommended)"
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (2 required)"
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Create NAT Gateway for private subnet egress (costs money)"
  default     = false
}

variable "engine_version" {
  type        = string
  description = "Aurora PostgreSQL engine version"
  default     = "15.13"
}

variable "db_name" {
  type        = string
  description = "Initial database name"
  default     = "appdb"
}

variable "master_username" {
  type        = string
  description = "Master username"
  default     = "postgres"
}

variable "master_password" {
  type        = string
  description = "Master password (use tfvars or env var; keep it secret)"
  sensitive   = true
}

variable "serverlessv2_min_acu" {
  type        = number
  description = "Serverless v2 min ACU (e.g., 0.5)"
  default     = 0.5
}

variable "serverlessv2_max_acu" {
  type        = number
  description = "Serverless v2 max ACU (e.g., 1 or 2 for cheap labs)"
  default     = 1
}

variable "deletion_protection" {
  type        = bool
  description = "Protect cluster from deletion"
  default     = false
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on destroy (labs often true)"
  default     = true
}

# KMS options
variable "manage_kms_key" {
  type        = bool
  description = "If true, Terraform creates a CMK for Aurora encryption"
  default     = true
}

variable "kms_key_arn" {
  type        = string
  description = "If manage_kms_key=false, provide an existing KMS key ARN"
  default     = null
}

variable "kms_deletion_window_in_days" {
  type        = number
  description = "KMS deletion window in days (7-30)"
  default     = 7
}
