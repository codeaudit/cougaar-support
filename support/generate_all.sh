#!/bin/bash

# run webalizer on cougaarforge.cougaar.org first
/usr/bin/webalizer -c /etc/webalizer/cougaarforge-webalizer.conf

for project in `ls /var/www/gforge-3.0/ | grep -v prototype | grep -v www | grep -v common`
do
	# create the usage directory if it's not there
	if [ ! -e "/var/www/gforge-3.0/$project/usage/" ]; then
		mkdir "/var/www/gforge-3.0/$project/usage/"
		cp /var/www/gforge-3.0/www/usage/msfree.png /var/www/gforge-3.0/$project/usage/
	fi

	# run webalizer on this project
	/usr/bin/webalizer -c /etc/webalizer/$project-webalizer.conf
done 
