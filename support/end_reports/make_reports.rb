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

=begin
On Wed, 2004-12-08 at 10:41, Art Marineau wrote:
> 
> Tom Copeland wrote:
> > > got any ideas on how we get the Documents on UltraForge and 
> > > CougaarForge 
> > > archived?
> > >     
> > We can dump the PostgreSQL database... although that would make it
> > difficult for anyone to get at the documents again, since they'd need to
> > have a GForge server running or at least understand that the docs are
> > base64 encoded and in a specific database file.
> 
> >   Might be nicer to put
> > them in a directory tree or some such.
> > 
> >   
> can you make this happen easily?

Hm.  I'm not sure.  It's worth a shot, though.  

But that's just a CougaarForge thing - which UltraForge docs were you
thinking about?  The ones in DocuShare?

> > > how about the WIKI pages?
> > >     
> > Hm.  We could just tar them up, along with the UseModWiki Perl script.
> >   
> ok, can you try this out and see what we get

Will do.

> >   
> > > and all the bugs in both Cougaar and UltraLog Bugzilla's
> > >     
> > <>
> > Grabbing the latest nightly DB dump should work for both of these...
> > although maybe we should include the bugzilla directory as well
> > since
> > someone would need that to get at the bugs (short of manually
> > queryingthe DB).
> ok wanna try this out once too?

Gladly.  
=end
