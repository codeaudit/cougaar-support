#!/usr/local/bin/ruby

require 'rubygems'
require 'postgres-pr/connection'

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
