# Provision public subnets in custom VPC
variable "public_subnet_cidrs" {
  default     = ["10.100.1.0/24", "10.100.2.0/24", "10.100.3.0/24"]
  type        = list(string)
  description = "DEV Public Subnet CIDRs"
}

variable "private_subnet_cidrs" {
  default     = ["10.100.4.0/24", "10.100.5.0/24", "10.100.6.0/24"]
  type        = list(string)
  description = "DEV Private Subnet CIDRs"
}

# VPC CIDR range
variable "vpc_cidr" {
  default     = "10.100.0.0/16"
  type        = string
  description = "DEV VPC to host webserver"
}

# Variable to signal the current environment 
variable "env" {
  default     = "dev"
  type        = string
  description = "Development Environment"
}
