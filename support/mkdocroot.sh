#!/bin/bash

group=$1
initialuser=$2

mkdir -p /var/www/gforge-projects/$group/usage/
touch /var/www/gforge-projects/$group/robots.txt
cp /var/www/gforge-projects/prototype/index.html /var/www/gforge-projects/$group/
cp /var/www/gforge-projects/prototype/usage/msfree.png /var/www/gforge-projects/$group/usage/
cp /var/www/gforge-projects/prototype/index.html /var/www/gforge-projects/$group/usage/
chown -R $initialuser:$group /var/www/gforge-projects/$group/
chmod -R 775 /var/www/gforge-projects/$group/
chmod -R g+s /var/www/gforge-projects/$group/
