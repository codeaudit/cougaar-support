#!/usr/local/bin/ruby

class Rec
	attr_reader :name, :count
	def initialize(name,count)
		@name = name
		@count = count
	end
	def to_s
		@name.ljust(30) + "\t" + @count.to_s
	end
end

recs = []
cmd = "psql -U gforge gforge -c \"\\dt\" | awk -F \"|\" '{print $2}'"
out=`#{cmd}`
out.split("\n").each { |line|
	line = line.strip
	if line == "" or line == "Name"
		next
		end
	res=`psql -U gforge gforge -c "select count(*) from #{line}"`
	if res.split("\n")[2] == nil
		recs << Rec.new(line, 0.to_i)
	else
		recs << Rec.new(line, res.split("\n")[2].strip.to_i)
	end
}

recs = recs.sort {|x,y| x.count <=> y.count}

total=0
recs.each {|rec| 
	puts rec
  total += rec.count
}

puts "Total: #{total}"
