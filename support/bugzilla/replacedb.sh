#!/bin/bash

mysql -u root -h cvs.ultralog.net --password="root" -e "drop database bugs"
mysql -u root -h cvs.ultralog.net --password="root" -e "create database bugs"
mysql -u root -h cvs.ultralog.net --password="root" -e "grant select,insert,update,delete,index,alter,create,drop,references on bugs.* to bugs@localhost identified by 'bugs'"
mysql -u root -h cvs.ultralog.net --password="root" -e "flush privileges"
mysql -u bugs --password="bugs" bugs < bugs2.sql
./ulbug_cleaner.rb

