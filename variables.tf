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

