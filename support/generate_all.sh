#!/bin/bash

# run webalizer on cougaarforge.cougaar.org first
/usr/bin/webalizer -c /etc/webalizer/cougaarforge-webalizer.conf

# run webalizer on all the logs after combining and sorting them
cat /usr/local/var/httpd/log/*access_log > /usr/local/var/httpd/log/all_access_log_unsorted
sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n /usr/local/var/httpd/log/all_access_log_unsorted > /usr/local/var/httpd/log/all_access_log
/usr/bin/webalizer -c /etc/webalizer/cougaarforge-all-webalizer.conf
rm /usr/local/var/httpd/log/all_access_log
rm /usr/local/var/httpd/log/all_access_log_unsorted

for project in `ls /var/www/gforge-3.0/ | grep -v prototype | grep -v www | grep -v common`
do
	# create the usage directory if it's not there
	if [ ! -e "/var/www/gforge-3.0/$project/usage/" ]; then
		mkdir "/var/www/gforge-3.0/$project/usage/"
		cp /var/www/gforge-3.0/www/usage/msfree.png /var/www/gforge-3.0/$project/usage/
		cp /root/webalizer/index.html /var/www/gforge-3.0/$project/usage/
	fi

	# run webalizer on this project
	/usr/bin/webalizer -c /etc/webalizer/$project-webalizer.conf
done 
