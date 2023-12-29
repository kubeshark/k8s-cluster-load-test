#!/bin/bash

# Set the ServerName in the Apache configuration
sed -i "s/#ServerName www.example.com:80/ServerName ${SERVER_NAME:-httpd-service}/" /usr/local/apache2/conf/httpd.conf

# Start Apache in the foreground
exec httpd-foreground
