#!/usr/local/bin/ruby

names = []
File.open("names.txt").each_line {|line|
	line.split(",").each {|n| names << n.chomp}
}

#toaddr = "tom@infoether.com"
toaddr = "noreply@cougaar.org"
names.each {|n|
	begin
		cmd = "mail #{toaddr} -s \"CFP: OpenCougaar Conference (colocated with AAMAS 2004)\" -b #{n} < message.txt"
		puts cmd
		`#{cmd}`
	rescue Exception
		puts "Failed to send to #{n}"
	end
}
