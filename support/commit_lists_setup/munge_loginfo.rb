#!/usr/local/bin/ruby

adminmap = {
"/cvsroot/micro/CVSROOT/loginfo"=>"wwright@bbn.com",
"/cvsroot/prototype/CVSROOT/loginfo"=>"ahelsing@bbn.com",
"/cvsroot/cougaarunit/CVSROOT/loginfo"=>"mabrams@cougaarsoftware.com",
"/cvsroot/cougaarlegacy/CVSROOT/loginfo"=>"ahelsing@bbn.com",
"/cvsroot/bol2/CVSROOT/loginfo"=>"mabrams@cougaarsoftware.com",
"/cvsroot/cougaaride/CVSROOT/loginfo"=>"mabrams@cougaarsoftware.com"
}

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
elsif ARGV[0] == "adminmap"
	adminmap.keys.each {|key|
		puts "Fixing #{key}"
		key.split("\n").each {|root|
			p = root.split("/")[2]
			`cvs -d /cvsroot/#{p}/ co CVSROOT`
			Dir.chdir("CVSROOT")
			`sed "s/tom@infoether.com/#{adminmap[key]}/" loginfo > tmp.loginfo && mv tmp.loginfo loginfo`	
			`sed "s:/cvsroot/commitmailer.sh:/usr/bin/syncmail:" loginfo > tmp.loginfo && mv tmp.loginfo loginfo`
			`cvs ci -m "Commits now use syncmail and also go to #{adminmap[key]} vs tom@infoether.com"`
			Dir.chdir("..")
			`rm -rf CVSROOT/`
		}
	}
else
	puts "no command given"
end


