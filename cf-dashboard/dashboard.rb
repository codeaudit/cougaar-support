#!/usr/local/bin/ruby

class Project
	def initialize(repo,mod,srcdir)
		@repo = repo
		@mod = mod
		@srcdir = srcdir
	end
end

class Build 
	def initialize
		@projects = []
	end
	def add_project(p)
		@projects << p
	end
	def get_third_party_jars
	end
	def build
		

end

if __FILE__ == $0
	b = Build.new
	b.add Project.new("/cvsroot/core","core","src")
	b.build
	
	puts "HI"
end
