#!/bin/bash

# get the 11.2 downloads
egrep "57006815|57130925|57947110" /usr/local/var/httpd/log/access_log > downloads_11_2.txt

# get the 11.0 downloads
egrep "60229842|60354572|56714309" /usr/local/var/httpd/log/access_log > downloads_11_0.txt

cat downloads_11_0.txt > final.txt
cat downloads_11_2.txt > final.txt

/usr/bin/webalizer -Q -c qpr.conf


