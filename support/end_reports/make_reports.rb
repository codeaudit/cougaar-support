#!/usr/local/bin/ruby

def tarwikis
	`mkdir cougaar_wikis`
	Dir.glob("/var/www/gforge-projects/**/wiki/").each {|d|
		`tar -zcf #{d.split("/")[4]}.tar.gz #{d}`
	}
	`tar -zcf cougaar_wikis.tar.gz cougaar_wikis/`
	`rm -rf cougaar_wikis/`
end

def getdocs
	`mkdir cougaar_docs`
	# query DB for all docs and the project name
	# for each project, create a dir
	# for each doc, wget the doc and put it in the dir
	# tar up project dir
	# delete project dir
	`tar -zcf cougaar_docs.tar.gz cougaar_docs/`
	`rm -rf cougaar_docs/`
end

def tarbugs
	`mkdir -p cougaar_bugs/bugzilla_db/`
	`mkdir cougaar_bugs/bugzilla_src/`
	`cp /var/backups/mysql/bugs/Tue.tar.gz cougaar_bugs/bugzilla_db/`	 
	`cp -r /var/www/bugzilla/ cougaar_bugs/bugzilla_src/`
	`tar -zcf cougaar_bugs.tar.gz cougaar_bugs/`
	`rm -rf cougaar_bugs/`
end

if ARGV[0] == "tarwikis"
elsif ARGV[0] == "getdocs"
elsif ARGV[0] == "tarbugs"
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
