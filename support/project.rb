#!/usr/local/bin/ruby

require 'fileutils'

WWW_DIR_PREFIX="/var/www/gforge-projects/"

=begin
Hi Rob -

OK, the ExNihilo project should be all set:

http://cougaar.org/projects/exnihilo/

You might want to read the "new project admin" checklist:

http://cougaar.org/docman/?group_id=7

If you have any questions, please post to the support forum:

http://cougaar.org/forum/forum.php?forum_id=6

Thanks!

Yours,

Tom
=end

class Project
  CVSROOT="/cvsroot/"
  VIEWCVS_CONF="/usr/local/viewcvs/viewcvs.conf"
  HTTPD_CONF="/usr/local/apache/conf/httpd.conf"
  APACHECTL="/usr/local/apache/bin/apachectl"
  HTTPD_LOG_DIR="/var/log/httpd/"
  REPLACE_PROJECT="csmart"
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
		setup_wiki
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
		puts "rm -rf /var/www/gforge3-files/#{@name}"
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
		Dir.glob('/cvsroot/*').collect {|x| x.split('/').last unless x =~ /(commitmailer|prototype)/}.compact
	end
	def wiki_dir(name)
		"#{WWW_DIR_PREFIX}#{name}/wiki/"
	end
	def fix_webalizer
		template = File.read("/etc/webalizer/csmart.conf")
		project_unix_names.each {|p| 
			next if p == "csmart"
			puts "Doing #{p}"
			File.open("/etc/webalizer/#{p}.conf", "w") {|file|
				template.each {|line|
					if line =~ /csmart/
						file.write(line.gsub(/csmart/, p))
					else
						file.write(line)
					end
				}
			}	
			#cmd  = "cat /etc/webalizer/csmart.conf | sed -e 's/csmart/#{p}/g' > /etc/webalizer/#{p}.conf"
			#puts "Doing #{p}: #{cmd}"
		}
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
		puts `#{APACHECTL} restart`
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
	elsif action == "fix-webalizer"
		g = GForge.new
		g.fix_webalizer
	else
		puts "Unknown action: #{action}"
	end
end
