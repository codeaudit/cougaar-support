#!/usr/local/bin/ruby

`mysql -u bugs --password="bugs" bugs -N -e 'select bug_id from bugs where product in ("OLDCOUGAAR", "OLDCougaarME", "OLDBLACKJACK", "OLDDELTA", "OLDJava", "OLDCSMART");' | cut -d " " -f 2 > buglist.txt`

bugids = []
File.new("buglist.txt").each {|line| bugids << line.chomp}

inclause = " ("
bugids.each {|id| 
	inclause.concat "'#{id}',"
}
inclause.chop!
inclause.concat ")"

# delete old bugs
tables_to_clean = []
tables_to_clean << "bugs" << "bugs_activity" << "cc" << "keywords" << "longdescs" << "votes"
tables_to_clean.each {|table|
	stmt = "delete from #{table} where bug_id in #{inclause}"
	`mysql -u bugs --password="bugs" bugs -N -e '#{stmt}'`
}

# delete old products
`mysql -u bugs --password="bugs" bugs -N -e 'delete from products where product in ("OLDCOUGAAR", "OLDCougaarME", "OLDBLACKJACK", "OLDDELTA", "OLDJava", "OLDCSMART");'`
`mysql -u bugs --password="bugs" bugs -N -e 'delete from milestones where product in ("OLDCOUGAAR", "OLDCougaarME", "OLDBLACKJACK", "OLDDELTA", "OLDJava", "OLDCSMART");'`
`mysql -u bugs --password="bugs" bugs -N -e 'delete from components where program in  ("OLDCOUGAAR", "OLDCougaarME", "OLDBLACKJACK", "OLDDELTA", "OLDJava", "OLDCSMART");'`
`mysql -u bugs --password="bugs" bugs -N -e 'delete from versions where program in ("OLDCOUGAAR", "OLDCougaarME", "OLDBLACKJACK", "OLDDELTA", "OLDJava", "OLDCSMART");'`

# set myself up as an admin
`mysql -u bugs --password="bugs" bugs -N -e 'update profiles set groupset="9223372036854775807" where login_name="tom@infoether.com";'`

# now need to add a new admin project and set it up to send emails to bugs-support@ultralog.net on new submissions
