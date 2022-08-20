# Module to deploy basic networking 
module "webservers-prod" {
  source = "../../../modules/aws_webservers"
  env                 = var.env
  instance_type       = var.instance_type
  my_private_ip       = var.my_private_ip
  my_public_ip        = var.my_public_ip
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  path_to_linux_key   = var.path_to_linux_key
  prefix              = module.globalvars.prefix
  default_tags        = module.globalvars.default_tags
}

module "globalvars" {
  source = "../../../modules/globalvars"
}