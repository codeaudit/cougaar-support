#!/usr/local/bin/ruby

require "rubygems"
require 'postgres-pr/connection'

newlists = "core,mts,webserver,glm,csmart,aggagent,community,util,vishnu,yp,build,qos,planning,servicediscovery,tutorials".split(",").collect!{|x| x + "-commits" }

conn = PostgresPR::Connection.new("gforge", "gforge")
newlists.each {|list|
	sql = "select u.email from users u, user_group ug, groups g where g.group_id in (select group_id from mail_group_list where list_name = '#{list}') and ug.group_id = g.group_id and u.user_id = ug.user_id"
	File.open(list + "-new-members.txt","w") { |f| 
		conn.query(sql).rows.each {|r| f.write(r[0] + "\n")}
	}
	cmd = "/usr/local/mailman/bin/add_members -r #{list}-new-members.txt #{list}"
	`#{cmd}`
}

