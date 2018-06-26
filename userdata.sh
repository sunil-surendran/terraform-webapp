#!/bin/bash
yum install httpd -y
echo "<html><center>" > /var/www/html/index.html
echo "<body style=\"background-color:powderblue;\">" >> /var/www/html/index.html
echo "<h2>This Webserver is served by Load Balancer and Auto Scaling Group from region us-west-2 </h2>" >> /var/www/html/index.html
echo "<h3>The current Web page is being served from the Instance having the hostname:</h3>" >> /var/www/html/index.html
echo "<font size=2 face=\"Helvetica\" color=red><b>" >> /var/www/html/index.html
curl http://169.254.169.254/latest/meta-data/local-hostname >> /var/www/html/index.html
echo "</b></font>"
echo "</center></html>"
systemctl start httpd
systemctl enable httpd

