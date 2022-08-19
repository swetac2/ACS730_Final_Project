#  Define the provider
provider "aws" {
  region = "us-east-1"
}

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use remote state to retrieve the data
data "terraform_remote_state" "network" { // This is to use Outputs from Remote State
  backend = "s3"
  config = {
    bucket = "GroupProject-bucket-${var.env}"  // Bucket from where to GET Terraform State
    key    = "${var.env}-network/terraform.tfstate" // Object name in the bucket to GET Terraform State
    region = "us-east-1"                            // Region where bucket created
  }
}

# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

# Define tags locally
locals {
  default_tags = merge(module.globalvars.default_tags, { "env" = var.env })
  prefix       = module.globalvars.prefix
  name_prefix  = "${local.prefix}-${var.env}"
}

# Retrieve global variables from the Terraform module
module "globalvars" {
  source = "../globalvars"
}

# Create Target group
resource "aws_lb_target_group" "tg" {
  name     = "tg-${var.env}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
  
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-targetgroup"
    }
  )
}


resource "aws_launch_template" "launch_template" {
  name   = "launch_template-${var.env}"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = var.instance_type
  key_name = aws_key_pair.linux_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile {
    name = "LabInstanceProfile"
  }
  user_data = filebase64("${path.module}/install_httpd.sh.tpl"
  )
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-launch-template"
    }
  )
}

resource "aws_autoscaling_group" "asg" {
  name = "asg-${var.env}"
  vpc_zone_identifier = [data.terraform_remote_state.network.outputs.private_subnet_ids[0], data.terraform_remote_state.network.outputs.private_subnet_ids[1], data.terraform_remote_state.network.outputs.private_subnet_ids[2]]
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  health_check_grace_period = 300
  health_check_type         = "ELB"

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg-instance"
    propagate_at_launch = true
  }
  
  dynamic "tag" {
    for_each = local.default_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  
}


# Create application load balancer
resource "aws_lb" "lb" {
  name               = "lb-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [data.terraform_remote_state.network.outputs.public_subnet_ids[0], data.terraform_remote_state.network.outputs.public_subnet_ids[1], data.terraform_remote_state.network.outputs.public_subnet_ids[2]]
  enable_deletion_protection = false

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-lb"
    }
  )
}

# Create load balancer listener
resource "aws_lb_listener" "listener"{
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Security Group for Application Load balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow HTTP traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-lb-sg"
    }
  )
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}

#Create Scaling policy 
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.name_prefix}_scale_down"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_description   = "Monitors CPU utilization for ASG"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  alarm_name          = "${local.name_prefix}_scale_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "5"
  evaluation_periods  = "2"
  period              = "120"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.name_prefix}_scale_up"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_description   = "Monitors CPU utilization for ASG"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = "${local.name_prefix}_scale_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "10"
  evaluation_periods  = "2"
  period              = "120"
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

# Provision SSH key pair for Ubuntu and AmazonLinux VMs
resource "aws_key_pair" "linux_key" {
  key_name   = "linux_key-${var.env}"
  public_key = file(var.path_to_linux_key)
  tags = merge({
    Name = "${local.prefix}-keypair"
    },
    local.default_tags
  )
}

# Security Group for Webserver
resource "aws_security_group" "web_sg" {
  name        = "allow_http_ssh"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description      = "HTTP from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.bastion_sg.id]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-web-sg"
    }
  )
}


# Bastion Instance 
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                     = aws_key_pair.linux_key.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  security_groups             = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-bastion"
    }
  )
}

# Security Group for bastion 
resource "aws_security_group" "bastion_sg" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${var.my_public_ip}/32", "${var.my_private_ip}/32"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-bastion-sg"
    }
  )
}

# Elastic IP
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-bastion-eip"
    }
  )
}