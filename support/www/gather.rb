#!/usr/local/bin/ruby

16.upto(23) {|x|
	puts "hour = #{x}"
	if x < 10
		print `grep "05/Nov/2003:0#{x}" /usr/local/var/httpd/log/access_log | wc -l`
	else
		print `grep "05/Nov/2003:#{x}" /usr/local/var/httpd/log/access_log | wc -l`
	end
	puts ""
}
