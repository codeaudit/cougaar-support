#!/usr/local/bin/ruby

projects = "core,mts,webserver,glm,csmart,aggagent,community,util,vishnu,yp,build,qos,planning,servicediscovery,tutorials,cws".split(",")
if ARGV[0] == "clear"
	puts "clearing"
	projects.each {|p|
		`rm -rf #{p}`
	}
elsif ARGV[0] == "checkout"
	projects.each {|p|
		Dir.mkdir(p)
		Dir.chdir(p)
		`cvs -d /cvsroot/#{p}/ co CVSROOT`
		Dir.chdir("..")
	}
elsif ARGV[0] == "update"
	projects.each {|p|
		Dir.chdir("#{p}/CVSROOT/")
		`sed "s/bbn.com/cougaar.org/" loginfo > tmp.loginfo && mv tmp.loginfo loginfo`	
		`cvs ci -m "Commits now go to #{p}-commits vs ul-core-detail"`
		Dir.chdir("../../")
	}
else
	puts "no command given"
end


