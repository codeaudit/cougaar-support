#!/usr/local/bin/ruby

names = []
#File.open("names.txt").each_line {|line| line.split(",").each {|n| names << n.strip.chomp} }
names << "tom@infoether.com"

#toaddr = "tom@infoether.com"
toaddr = "noreply@cougaar.org"
names.each {|n|
	begin
		cmd = "mail #{toaddr} -s \"OpenCougaar Conference (colocated with AAMAS 2004): Program and Keynote\" -b #{n} < message.txt"
		puts cmd
		`#{cmd}`
	rescue Exception
		puts "Failed to send to #{n}"
	end
}
