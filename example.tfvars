region           = "eu-west-2"
name             = "lab-ec2-docker-postgres"
instance_type    = "t3.small"
key_name         = "labec2"
# my public IP with /32
allowed_ssh_cidr = "/32"

#######################################
# Database Credentials
#######################################

# Master password for Aurora
# (Do NOT commit this file to GitHub)
master_password = ""


#######################################
# Aurora Serverless v2 Scaling
#######################################

# Cheap lab-friendly scaling
serverlessv2_min_acu = 0.5
serverlessv2_max_acu = 1


#######################################
# Safety / Lifecycle Controls
#######################################

# Allow easy cleanup for labs
deletion_protection = false
skip_final_snapshot = true


#######################################
# KMS (Encryption at Rest)
#######################################

# Let Terraform manage the CMK
manage_kms_key = true

# Only needed if manage_kms_key = false
# kms_key_arn = "arn:aws:kms:region:account-id:key/key-id"

# Short deletion window for labs
kms_deletion_window_in_days = 7

# NAT costs money; keep false for labs unless you need private subnet egress
enable_nat_gateway = false