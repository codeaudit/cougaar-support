#!/usr/local/bin/ruby

require 'fileutils'

WWW_DIR_PREFIX="/var/www/gforge-projects/"

class Project
  CVSROOT="/cvsroot/"
  VIEWCVS_CONF="/usr/local/viewcvs/viewcvs.conf"
  HTTPD_CONF="/usr/local/etc/httpd/httpd.conf"
  HTTPD_LOG_DIR="/usr/local/var/httpd/log/"
  REPLACE_PROJECT="csmart"
  APACHECTL="/usr/local/sbin/apachectl"
	attr_reader :name
	def initialize(name)
		@name = name
	end
	def create(admin)
		add_group_and_user(admin)
		create_docroot_and_repo(admin)
		update_unix_accounts
		create_webalizer
		add_vhost	
		add_to_viewcvs_conf
		#setup_wiki
	end
	def delete
		puts "Delete the #{@name} vhost from #{HTTPD_CONF}"
		puts "Delete the #{@name} ViewCVS entry from #{VIEWCVS_CONF}"
		puts "Run the following commands if they look OK"
		puts "rm -f /etc/webalizer/#{@name}.conf" if File.exists?("/etc/webalizer/#{@name}.conf")
		puts "rm -f #{HTTPD_LOG_DIR}#{@name}-access_log" if File.exists?("#{HTTPD_LOG_DIR}#{@name}-access_log")
		puts "rm -f #{HTTPD_LOG_DIR}#{@name}-error_log" if File.exists?("#{HTTPD_LOG_DIR}#{@name}-error_log")
		puts "rm -rf #{CVSROOT}#{@name}"
		puts "rm -rf /var/www/gforge-projects/#{@name}"
	end
	def add_group_and_user(admin)
		`/usr/sbin/groupadd #{@name}`
		if !File.exists?("/home/#{admin}")
			`/usr/sbin/useradd -g #{@name} -s /bin/cvssh #{admin}`
		end
	end
	def create_docroot_and_repo(admin) 
		`./mkdocroot.sh #{@name} #{admin}`
		`./cvscreate.sh #{@name} #{admin}`
	end
	def update_unix_accounts
		`/root/gforge/update_unix_accounts.php`
	end
	def create_webalizer
		`cat /etc/webalizer/#{REPLACE_PROJECT}.conf | sed -e 's/#{REPLACE_PROJECT}/#{@name}/g' > /etc/webalizer/#{@name}.conf`
	end
	def add_vhost
		template=[]
		File.new("httpd.entry.template").each {|line|
			if line =~ /projectname/
				line.gsub!("projectname", @name)
			end
			template << line
		}
		httpd=[]
		File.new(HTTPD_CONF).each{|line|
			if line =~ /#PLACEHOLDER#/
				template.each {|t| httpd << t }
			else
				httpd << line
			end
		}
		File.open(HTTPD_CONF, "w") {|f| f.write(httpd) }
		puts `#{APACHECTL} restart`
		`cp #{HTTPD_CONF} .`
	end
	def add_to_viewcvs_conf
		viewcvs=[]
		File.new(VIEWCVS_CONF).each{|line|
		  if line =~ /#{REPLACE_PROJECT}/
		  	viewcvs << "            #{@name}  :  #{CVSROOT}#{@name},\n"
		  end
		  viewcvs << line
		}
		File.open(VIEWCVS_CONF, "w") {|f| f.write(viewcvs) }
		`cp #{VIEWCVS_CONF} .`
	end
	def setup_wiki
		FileUtils.mkdir_p("#{wiki_dir(@name)}html")
		`cp usemod_wiki_template/wiki.pl #{wiki_dir(@name)}`
		`ruby -pe "gsub('Template', '#{@name[0].chr.upcase + @name[1,@name.length-1]}')" #{wiki_dir(@name)}/wiki.pl`
		`cp usemod_wiki_template/wiki.css #{wiki_dir(@name)}`	
		`chown webuser:webgroup #{wiki_dir(@name)}html`
		`chmod g+s #{wiki_dir(@name)}html`
	end
	def wiki_dir(name)
		"#{WWW_DIR_PREFIX}#{name}/wiki/"
	end
end

class GForge
	def project_unix_names	
		# obtained via ruby -e "Dir.glob('/var/cvs/*').each {|x| print '\"' + x.split('/').last + '\",' unless x =~ /(commitmailer|prototype)/}"
		#["support"]
		["support","rendezvous","jabber4r","muravey-tools","r-lijo","vapor","rdsl","rmagick","rucene","vim-ruby","rubyjdwp","aeditor","rvv","rgenetic","bytecoderuby","rsort","rubymusic","rexslt","czytacz","ruby-ptbr","crush","breeze","minirubywiki","rubymirror","freeride","whizzbot","musicextras","junction","wxruby","purple","rubydotnetproxy","osx-dist","mp3control","ikko","rpp","gurgitate-mail","lafcadio","svgcanvas","rjni","colorparser","tldlib","iptcext","rake","extmath","cerise","mp3taglib","raimbo","log-debug","rimport","rash","redwood","monkeys","ruby-freedb","ruby-serialport","ruby-mp3info","quixml","rchemy","diaria","rubydotnet","v4lradio","rcalc","nakedruby","simplemail","radical","bin2hex","arbypod","rublog","enterprise-ruby","ruby-htmltools","natcmp","ruby-cvs-exp","rubex","ruby-pdf","lwtools","rubyplayer","ruwiki","win32utils","stdlib-doc","rjay","fox-tool","extensions","qt2fxruby","lmbk","bermud","canto","ratify","winjobscheduler","lego-mindstorms","ai-app-prog","tsql-analyzer","prime","rimage","kane","speed-reader","encml","wtr","lifeinart","wise","text-highlight","roughcut","ned","rgl","rubylucene","sds","sws","ruminate","rcoaster","webspike-ruby","finance-tvm","xmldigester","rms","scrabbler","rubybnc","fcca","vrtools","alph","baker","rubygems","littlelexer","uuid","osx-substrate","ros","libxosd-ruby","cvspassman","ooo4r","ruby-doom","rubric","rubyfxgen","rexpect","htaccess","rabble","net-ldap","tourneybot","ripper","ruby-libburn","runt","borges","simplewiki","yamali","p2501","rubygo","getoptdeclare","petite","vhostadmin","rage","drbfire","win32console","blogsight","attribute","rbmud","dime","lpx","rubyinstaller","labyrinth","yarv","ecal","ruby-rdf","rvsh","rgplot","red","rforum","rubytests","rubylove","korundum","mutabletime","activerecord","poignant","cardinal","tycho","instiki","lolita","rssscraper","ore","rubirc","htmltokenizer","whyruby","pqa","ruby-helix","sql-serialize","rsp-parser","qworker","iowa","copeland","rextra","copland","heise","log4r","kansas","rdocweb","alexandria","rant","ruby-cookbook","sasha","rubydevelop","tempura","captcha","redcloth","hobix","sympop","mycash","vpim","rboard","oscar","yo-lib","v8e","syck","rumpus","iforead","rsmarty","thebrain","speedreader","bluecloth","linguistics","arrow","objectgraph","ruby-dbi","surveyor","geekast","agoricnim","suite","irr","lpt","evil","chump-change","memone","ezgtk","xboot","packrat","ivpvr","actionpack","rdf-redland","railties","rna","sqlite-ruby","mahoro","ruby-oci8","petstore","gnucap","ruby-de","chicagogroup","rpa-base","coral","rubyhelper","grouch","interface","battery","n3randomworld","dev-utils","r4ruby","linalg","chun","net-ssh"]
	end
	def wiki_dir(name)
		"#{WWW_DIR_PREFIX}#{name}/wiki/"
	end
	def wiki_setup_files
		project_unix_names.each {|p|
			if File.exists?(wiki_dir(p))
				puts "Skipping #{p}"
				next
			end
			puts "Setting up Wiki for #{p}"
			p = Project.new(p)
			p.setup_wiki
		}	
	end
	def wiki_setup_httpd
		httpd=[]
		File.new("httpd.conf").each{|line|
			if line =~ /\<\/VirtualHost\>/
				if httpd.last =~ /Directory/ # skip sites that already have a Wiki
					httpd << line
					next
				end
				proj = httpd.last.strip.split("/").last.split("-error_log").first
				httpd << " <Directory \"/var/www/gforge-projects/#{proj}/wiki/\">\n"
				httpd << "  AddHandler cgi-script .pl\n"
				httpd << "  Options ExecCGI\n"
				httpd << "  AllowOverride All\n"
				httpd << "  Order allow,deny\n"
				httpd << "  Allow from all\n"
				httpd << " </Directory>\n"
			end
			httpd << line
		}
		File.open("httpd.conf.new", "w") {|f| f.write(httpd) }
		#puts `#{APACHECTL} restart`
	end
end

if __FILE__ == $0
	raise "Usage: " + $0 + " -action (create|delete|wikis) [-name fiddle] [-admin joe]" if ARGV == nil || !ARGV.include?("-action")
	action = ARGV[ARGV.index("-action")+1]
	if action == "create"
		raise "Pass in a -admin parameter to create a project" if !ARGV.include?("-admin")
		raise "Pass in a -name parameter to create a project" if !ARGV.include?("-name")
		p = Project.new(ARGV[ARGV.index("-name")+1])
		p.create(ARGV[ARGV.index("-admin")+1])
	elsif action == "delete"
		raise "Pass in a -name parameter to create a project" if !ARGV.include?("-name")
		p = Project.new(ARGV[ARGV.index("-name")+1])
		p.delete
	elsif action == "wiki-setup-files"
		g = GForge.new
		g.wiki_setup_files
	elsif action == "wiki-setup-httpd"
		g = GForge.new
		g.wiki_setup_httpd
	else
		puts "Unknown action: #{action}"
	end
end
