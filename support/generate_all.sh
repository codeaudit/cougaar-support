#!/bin/bash

# run webalizer on bugs.cougaar.org first
/usr/bin/webalizer -c /etc/webalizer/bugs.cougaar.org-webalizer.conf

# then run webalizer on cougaarforge.cougaar.org 
/usr/bin/webalizer -c /etc/webalizer/cougaarforge-webalizer.conf

# combine all the logs (except Bugzilla)
for file in `find /usr/local/var/httpd/log/ -name "*access_log" | grep -v bugs`
do
        cat $file >> /usr/local/var/httpd/log/all_access_log_unsorted
done

# sort the combined log
sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n /usr/local/var/httpd/log/all_access_log_unsorted > /usr/local/var/httpd/log/all_access_log

# run Webalizer on it
/usr/bin/webalizer -c /etc/webalizer/cougaarforge-all-webalizer.conf
rm /usr/local/var/httpd/log/all_access_log
rm /usr/local/var/httpd/log/all_access_log_unsorted

for project in `ls /var/www/gforge-projects/ | grep -v prototype `
do
	# create the usage directory if it's not there
	if [ ! -e "/var/www/gforge-projects/$project/usage/" ]; then
		mkdir "/var/www/gforge-projects/$project/usage/"
		cp /var/www/gforge-projects/prototype/usage/msfree.png /var/www/gforge-projects/$project/usage/
		cp /root/webalizer/index.html /var/www/gforge-projects/$project/usage/
	fi

	# run webalizer on this project
	/usr/bin/webalizer -c /etc/webalizer/$project-webalizer.conf
done 
