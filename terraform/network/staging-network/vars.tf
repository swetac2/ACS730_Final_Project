# Provision public subnets in custom VPC
variable "public_subnet_cidrs" {
  default     = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
  type        = list(string)
  description = "Staging Public Subnet CIDRs"
}

variable "private_subnet_cidrs" {
  default     = ["10.200.4.0/24", "10.200.5.0/24", "10.200.6.0/24"]
  type        = list(string)
  description = "Staging Private Subnet CIDRs"
}

# VPC CIDR range
variable "vpc_cidr" {
  default     = "10.200.0.0/16"
  type        = string
  description = "Staging VPC to host webserver"
}

# Variable to signal the current environment 
variable "env" {
  default     = "staging"
  type        = string
  description = "Staging Environment"
}
