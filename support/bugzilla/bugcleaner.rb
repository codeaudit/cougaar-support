#!/usr/local/bin/ruby

name = ARGV[0]
if name == nil
	puts "Supply a name to delete"
	exit
end

puts "Getting the list of bug ids to delete"
`mysql -u bugs --password="bugs" bugs -N -e 'select bug_id from bugs where product in ("#{name}");' | cut -d " " -f 2 > buglist.txt`

bugids = []
File.new("buglist.txt").each {|line| bugids << line.chomp}

inclause = " ("
bugids.each {|id| 
	inclause.concat "'#{id}',"
}
inclause.chop!
inclause.concat ")"

puts "Deleting #{bugids.length} bugs from various tables"
tables_to_clean = []
tables_to_clean << "bugs" << "bugs_activity" << "cc" << "keywords" << "longdescs" << "votes"
tables_to_clean.each {|table|
	stmt = "delete from #{table} where bug_id in #{inclause}"
	`mysql -u bugs --password="bugs" bugs -N -e '#{stmt}'`
}

puts "Deleting the #{name} product and program from various tables"
`mysql -u bugs --password="bugs" bugs -N -e 'delete from products where product in ("#{name}");'`
`mysql -u bugs --password="bugs" bugs -N -e 'delete from milestones where product in ("#{name}");'`
`mysql -u bugs --password="bugs" bugs -N -e 'delete from components where program in  ("#{name}");'`
`mysql -u bugs --password="bugs" bugs -N -e 'delete from versions where program in ("#{name}");'`
