#!/usr/bin/env bash

sudo yum update -y
sudo yum install -y httpd
sudo systemctl enable httpd
sudo systemctl start httpd

sudo cat > /var/www/html/index.html <<EOF
<h1>Hello World!</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
EOF
