#!/usr/local/bin/ruby

class Fixer
	def update_all_bug_ids
		File.open("sql.txt", "w") {|f|
			tables= ["bugs", "bugs_activity", "cc", "keywords", "longdescs", "votes"]
			get_ids_from_sql("select bug_id from attachments where bug_id < 10000").each { |line|
				oldid = line.chomp
				newid = (oldid.to_i + 10000).to_s
				tables.each {|t| f << "update #{t} set bug_id = #{newid} where bug_id = #{oldid};\n" }
			}
		}
	end
	def update_attachment_bug_ids
		attachment_table_ids = get_ids_from_sql("select bug_id from attachments where bug_id < 10000")
		bug_table_ids = get_ids_from_sql("select bug_id from bugs")
		attachment_table_ids.delete_if {|id| !bug_table_ids.include?((id.to_i+10000).to_s) }	
		File.open("sql.txt", "w") {|f|
			attachment_table_ids.each {|id|
				f << "update attachments set bug_id = #{id.to_i + 10000} where bug_id = #{id};\n"
			}
		}
	end
	def delete_cougaar_attachments
		File.open("sql.txt", "w") {|f|
			get_ids_from_sql("select bug_id from attachments where bug_id < 10000").each {|id|
				f << "delete from attachments where bug_id = #{id};\n"
			}
		}
	end
	def delete_cougaar_dependencies
		dep_ids = get_ids_from_sql("select dependson from dependencies where dependson < 10000")
		bug_table_ids = get_ids_from_sql("select bug_id from bugs")
		dep_ids.delete_if {|id| bug_table_ids.include?((id.to_i+10000).to_s) }	
		File.open("sql.txt", "w") {|f|
			dep_ids.each {|id| f << "delete from dependencies where dependson = #{id};\n" }
		}
	end
	def get_ids_from_sql(cmd)
		ids = []
		`#{wrap_sql_cmd(cmd)} | cut -d " " -f 2`.each { |line| ids << line.chomp }
		ids
	end
	def wrap_sql_cmd(cmd)
		"mysql -u bugs --password=\"bugs\" bugs -N -e '#{cmd};'"
	end
end

if __FILE__ == $0
	f = Fixer.new
	f.delete_cougaar_dependencies
	# to run the SQL, do a:
	#`mysql -f -u bugs --password="bugs" bugs < sql.txt`
end

