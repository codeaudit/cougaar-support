#!/usr/local/bin/ruby

require 'rubygems'
require 'postgres-pr/connection'

def gids
	dirs = [	
	"/var/www/gforge-projects/",
	"/cvsroot/"
	]

	map = {}

	conn = PostgresPR::Connection.new("gforge", "gforge")
	sql = "select u.user_name, g.unix_group_name from users u, user_group ug, groups g where ug.admin_flags = 'A' and u.user_id = ug.user_id and ug.group_id = g.group_id and g.status ='A'"
	conn.query(sql).rows.each {|r| 
		map[r[1]] = r[0]
	}

	map.keys.each {|k|
		dirs.each {|d|
			cmd = "chown -R #{map[k]}:#{k} #{d}#{k}"
			puts cmd
			`#{cmd}`
		}
	}
end

def wikis
	Dir.glob("/var/www/gforge-projects/**/wiki/html").each {|d|
		cmd = "chown -R webuser:webgroup #{d}"
		puts cmd
		`#{cmd}`
	}
end

def groupwrite
	Dir.glob("/var/www/gforge-projects/*").each {|d|
		cmd = "chmod -R g+w #{d}"
		puts cmd
		`#{cmd}`
	}
end

if ARGV[0] == "wikis"
	puts "Fixing wikis"
	wikis
elsif ARGV[0] == "gids"
	puts "Fixing gids"
	gids
elsif ARGV[0] == "groupwrite"
	puts "Setting project dirs to g+w"
	groupwrite
else 
	puts "Usage: fix.rb <wikis|gids>"
end
