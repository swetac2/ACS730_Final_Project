# Default tags
variable "default_tags" {
  default     = {}
  type        = map(any)
  description = "Default tags to be appliad to all AWS resources"
}

# Name prefix
variable "prefix" {
  type        = string
  description = "Name prefix"
}

# Instance type
variable "instance_type" {
  description = "Type of the instance"
  type        = string
}

# Variable to signal the current environment 
variable "env" {
  type        = string
  description = "Deployment Environment"
}

#Private Ip of the Admin
variable "my_private_ip" {
  type        = string
  description = "Private IP of the Admin"
}

#Public Ip of the Admin
variable "my_public_ip" {
  type        = string
  description = "Public IP of the Admin"
}


variable "min_size" {
  type        = number
  description = "Minimum size of VMs to add in ASG"
}

variable "max_size" {
  type        = number
  description = "Maximum size of VMs to add in ASG"
}

variable "desired_capacity" {
  type        = number
  description = "Desired of VMs to add in ASG"
}


variable "path_to_linux_key" {
  description = "Path to the public key to use in every VMs provisioning"
  type        = string
}