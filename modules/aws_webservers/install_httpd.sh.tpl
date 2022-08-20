#!/bin/bash
sudo yum -y update
sudo yum -y install httpd
myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
sudo aws s3 cp s3://images-bucket-group30/ /var/www/html --recursive
echo "<h1>Welcome to ACS730 ${prefix} webserver deployed by Jay Patel & Sweta Panchal! My private IP is $myip in ${env} environment</font></h1><br>Built by Group123. <img src="newr.jpg" alt="first"> <br> <img src="sac.jpg" alt="second">" > /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable httpd

