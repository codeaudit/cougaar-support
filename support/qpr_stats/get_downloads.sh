#!/bin/bash

# Get the entries out of the log
# 11.2.2 -> 57940054 bytes
# 11.2 -> "57006815|57130925|57947110" bytes
# 11.0 -> "60229842|60354572|56714309" bytes
egrep "57006815|57130925|57947110|57940054|60229842|60354572|56714309" /var/log/httpd/access_log > final.txt

# Move everything into December so that the country pie chart will show where
# all the downloads came from
sed -e 's/Nov/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Oct/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Sep/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Aug/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Jul/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Jun/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Apr/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/May/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Mar/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Feb/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt
sed -e 's/Jan/Dec/g' final.txt > final.txt.tmp && mv -f final.txt.tmp final.txt

# Sort it to make webalizer happy
sort -t ' ' -k 4.9,4.12n -k 4.5,4.7M -k 4.2,4.3n -k 4.14,4.15n -k 4.17,4.18n -k 4.20,4.21n final.txt > final.sorted

/usr/bin/webalizer -i -c qpr.conf


