#!/usr/local/bin/ruby

0.upto(23) {|x|
	puts "hour = #{x}"
	if x < 10
		print `grep "04/Nov/2003:0#{x}" /usr/local/var/httpd/log/access_log | wc -l`
	else
		print `grep "04/Nov/2003:#{x}" /usr/local/var/httpd/log/access_log | wc -l`
	end
	puts ""
}
