#!/usr/local/bin/ruby

def tarwikis
	`mkdir cougaar_wikis`
	puts "Globbing"
	Dir.glob("/var/www/gforge-projects/**/wiki/").each {|d|
		puts "Processing #{d}"
		`tar -zcf cougaar_wikis/#{d.split("/")[4]}.tar.gz #{d}`
	}
	`tar -zcf wikis.tar.gz cougaar_wikis/`
	#`rm -rf cougaar_wikis/`
end

def getdocs
	`psql -q -t -U gforge gforge -c "select g.unix_group_name, d.group_id, d.docid, d.filename from groups g, doc_data d where d.stateid = 1 and d.group_id = g.group_id and g.status = 'A' order by g.group_id" > files.txt`
	Dir.mkdir("docs") if !File.exists?("docs")
	File.read("files.txt").split("\n").each {|line|
		proj, gid, did, name = *(line.split("|"))
		proj.strip!
		gid.strip!
		did.strip!
		name.strip!
		puts "Processing #{name}"
		url = "http://cougaar.org/docman/view.php/#{gid}/#{did}/#{name}"
		cmd = "wget -q \"#{url}\""
		`#{cmd}`
		Dir.mkdir("docs/#{proj}") if !File.exists?("docs/#{proj}")
		`mv "#{name}" docs/#{proj}/`
	}
end

def tarbugs
	`cp /var/backups/mysql/bugs/Mon.tar.gz mysql_bugzilla_database_backup.tar.gz`	 
	`tar -zcf bugzilla-2.16.5-source.tar.gz /var/www/bugzilla-2.16.5/`
end

if ARGV[0] == "tarwikis"
	tarwikis
elsif ARGV[0] == "getdocs"
	getdocs
elsif ARGV[0] == "tarbugs"
	tarbugs
else
	puts "Usage: make_reports.rb <tarwikis|getdocs|tarbugs>"
end
