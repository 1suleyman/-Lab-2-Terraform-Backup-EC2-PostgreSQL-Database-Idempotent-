variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_cidrs" {
  type = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "public_subnet_cidrs must contain at least 2 CIDRs."
  }
}

variable "private_subnet_cidrs" {
  type = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "private_subnet_cidrs must contain at least 2 CIDRs."
  }
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Create NAT Gateway for private subnet egress"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
  default     = {}
}
