# ACS730_Final_Project

# ACSFinalProject-group123
To deploy the project infrastructure using terraform, follow below steps

#################################################################################################################################################################################

Pre-requisites:
a) Clone the code from below Github repository link into  Cloud9 environment
Link:

b) Make 3 ssh keys for the EC2 instances for all the different environments:
	ssh-keygen -t rsa -f ~/.ssh/group123-dev
	ssh-keygen -t rsa -f ~/.ssh/group123-staging
	ssh-keygen -t rsa -f ~/.ssh/group123-prod

c) Make 4 S3 buckets for 3 different environments & 1 to store images:
	group123-bucket-dev
	group123-bucket-staging
	group123-bucket-prod
    images-bucket-group123	
	      Upload images to the above bucket and change the images name to the "install_httpd.sh.tpl" file in the path "~/environment/ACSFinalProject-group123/modules/aws_webservers"

d) Give AWS Cloud9 Public & Private instance IP address in the "variable.tf" file in webservers of different environments. This is to guarantee that we can login to our bastion

*****************************************************                  *****************************************************


                                                     How to implement Code:


1) In order to create the dev environment run the below command lines.
	
	For Network module:

	cd ~/environment/ACSFinalProject-group123/terraform/network/dev-network
	terraform init
	terraform plan
	terraform apply --auto-approve

	For Webserver module:

	cd ~/environment/ACSFinalProject-group123/terraform/webservers/dev-webserver
	terraform init
	terraform plan
	terraform apply --auto-approve

1) Run the below commands to create the staging environment.

	For Network module:

	cd ~/environment/ACSFinalProject-group123/terraform/network/staging-network
	terraform init
	terraform plan
	terraform apply --auto-approve

	For Webserver module:
	cd ~/environment/ACSFinalProject-group123/terraform/webservers/staging-webserver
	terraform init
	terraform plan
	terraform apply --auto-approve

1) Run the below commands to create the prod environment
	
	For Network module:
	cd ~/environment/ACSFinalProject-group123/terraform/network/prod-network
	terraform init
	terraform plan
	terraform apply --auto-approve

	For Network module:
	cd ~/environment/ACSFinalProject-group123/terraform/webservers/prod-webserver
	terraform init
	terraform plan
	terraform apply --auto-approve



*****************************************************                  *****************************************************

Cleanup:
1) It is necessary to delete all the resources as it will cost us. We can follow below commands to delete the resources in the idle sequence.
Commands:

	cd ~/environment/ACSFinalProject-group123/terraform/webservers/dev-webserver
	terraform destroy --auto-approve

	cd ~/environment/ACSFinalProject-group123/terraform/network/dev-network
	terraform destroy --auto-approve

	cd ~/environment/ACSFinalProject-group123/terraform/webservers/staging-webserver
	terraform destroy --auto-approve

	cd ~/environment/ACSFinalProject-group123/terraform/network/staging-network
	terraform destroy --auto-approve

	cd ~/environment/ACSFinalProject-group123/terraform/webservers/prod-webserver
	terraform destroy --auto-approve

	cd ~/environment/ACSFinalProject-group123/terraform/network/prod-network
	terraform destroy --auto-approve


