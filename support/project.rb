#!//usr/local/bin/ruby

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
	def create(firstuser)
		add_group_and_user(firstuser)
		create_docroot_and_repo(firstuser)
		update_unix_accounts
		create_webalizer
		add_vhost	
		add_to_viewcvs_conf
	end
	def delete
		puts "Delete the #{@name} vhost from #{HTTPD_CONF}"
		puts "Delete the #{@name} ViewCVS entry from #{VIEWCVS_CONF}"
		puts "Run the following commands if they look OK"
		puts "rm /etc/webalizer/#{@name}.conf" if File.exists?("/etc/webalizer/#{@name}.conf")
		puts "rm #{HTTPD_LOG_DIR}#{@name}-access_log" if File.exists?("#{HTTPD_LOG_DIR}#{@name}-access_log")
		puts "rm #{HTTPD_LOG_DIR}#{@name}-error_log" if File.exists?("#{HTTPD_LOG_DIR}#{@name}-error_log")
		puts "rm -rf #{CVSROOT}#{@name}"
		puts "rm -rf /var/www/gforge-projects/#{@name}"
	end
	def add_group_and_user(firstuser)
		`/usr/sbin/groupadd #{@name}`
		if !File.exists?("/home/#{firstuser}")
			`/usr/sbin/useradd -g #{@name} -s /bin/cvssh #{firstuser}`
		end
	end
	def create_docroot_and_repo(firstuser) 
		`./mkdocroot.sh #{@name} #{firstuser}`
		`./cvscreate.sh #{@name} #{firstuser}`
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
end

if __FILE__ == $0
	raise "Usage: " + $0 + " -action (create|delete) [-name fiddle] [-firstuser joe]" if ARGV == nil || !ARGV.include?("-name") || !ARGV.include?("-action")
	p = Project.new(ARGV[ARGV.index("-name")+1])
	action = ARGV[ARGV.index("-action")+1]
	if action == "create"
		raise "Pass in a -firstuser parameter to create a project" if !ARGV.include?("-firstuser")
		p.create(ARGV[ARGV.index("-firstuser")+1])
	elsif action == "delete"
		p.delete
	else
		puts "Unknown action: #{action}"
	end
end
