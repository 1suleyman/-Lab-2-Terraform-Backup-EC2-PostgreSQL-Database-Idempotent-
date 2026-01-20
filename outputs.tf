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

