# Provision public subnets in custom VPC
variable "public_subnet_cidrs" {
  default     = ["10.250.1.0/24", "10.250.2.0/24", "10.250.3.0/24"]
  type        = list(string)
  description = "Prod Public Subnet CIDRs"
}

variable "private_subnet_cidrs" {
  default     = ["10.250.4.0/24", "10.250.5.0/24", "10.250.6.0/24"]
  type        = list(string)
  description = " Prod Private Subnet CIDRs"
}

# VPC CIDR range
variable "vpc_cidr" {
  default     = "10.250.0.0/16"
  type        = string
  description = "Prod VPC to host webserver"
}

# Variable to signal the current environment 
variable "env" {
  default     = "prod"
  type        = string
  description = "Production Environment"
}
