#!/usr/local/bin/ruby

`find /var/www/gforge-projects/ -name wiki`.split("\n").each {|x| 
	puts "Deploying to #{x}"
	`cp wiki.pl #{x}` 
}
