#!/usr/local/bin/ruby

require 'ikko.rb'
require 'rexml/document'

class Project
	attr_reader :repo, :mod, :srcdir, :tag, :title
	def initialize(title,repo,mod,srcdir,tag)
		@title = title
		@repo = repo
		@mod = mod
		@srcdir = srcdir
		@tag = tag
	end
  def ant_xml_output
    preamble + "_ant.xml"
  end
  def ant_text_output
    preamble + "_ant.txt"
  end
  def ncss_output
    preamble + "_ncss.txt"
  end
  def pmd_output
    preamble + "_pmd.html"
  end
  def cpd_output
    preamble + "_cpd.txt"
  end
  def preamble
    @repo + "_" + @mod + "_" + @tag
  end
	def check_out
		cmd = "cd #{Build::TMP} && cvs -Q -d" + Build::CVS_ROOT + @repo + " co " + @mod + " && cd .."
		`#{cmd}`
	end
end

class BuildResult
	attr_accessor :compile_succeeded, :deprecation_warnings, :built_at, :loc, :cpd
	attr_reader :pmd
	def initialize 
		@pmd = 0
		@cpd = 0
	end
	def parse_pmd_output(f)
    if !File.exists?(Build::PMD + f) or File.size(Build::PMD + f) < 12
      return
    end
    File.new(Build::PMD + f).each("<td ") {|x| @pmd += 1}
    @pmd=(@pmd/4) unless @pmd==0
	end
end

class Build 
	CVS_ROOT = ":pserver:anonymous@cougaar.org:/cvsroot/"
	TMP = "working/"
	PMD = "pmd/"
	CPD = "cpd/"
	BUILD = "build/"
	REPORTS = "reports/"
	WWW = "tom@cougaar.org:/var/www/gforge-projects/support/build/"
	def initialize(verbose)
		@projects = []
		@verbose = verbose
   	Dir.mkdir(TMP) unless File.exist? TMP
   	Dir.mkdir(CPD) unless File.exist? CPD
   	Dir.mkdir(PMD) unless File.exist? PMD
   	Dir.mkdir(BUILD) unless File.exist? BUILD
   	Dir.mkdir(TMP + "build") unless File.exist? TMP + "build"
   	Dir.mkdir(REPORTS) unless File.exist?(REPORTS)
		glom_classpath
	end
	def add_project(p)
		@projects << p
	end
	def render
		fm=Ikko::FragmentManager.new
    fm.base_path="./"
    output=fm["header.frag"]
		@projects.each {|p| 	
			puts "Rendering " + p.title + "/" + p.mod if @verbose
			br = BuildResult.new
			parse_ant_build_output(prepend_working_dir(p.ant_xml_output),br)
			br.loc = parse_element(REPORTS + "/" + p.ncss_output, "javancss/ncss")
			br.parse_pmd_output(p.pmd_output)
      pmd="<a href=\"#{PMD}#{p.pmd_output}\">#{br.pmd.to_s}</a>" unless br.pmd == 0
			parse_cpd_output(p.cpd_output, br)
      if br.cpd == 0
      	cpd="0"
      elsif br.cpd == "TBD"
        cpd="TBD"
      else
        cpd="<a href=\"#{CPD}/#{p.cpd_output}\">#{br.cpd}</a>"
      end
			output << fm["row.frag", {"title"=>p.title, 		
																"color"=>br.compile_succeeded ? "#00FF00" : "red", 
																"module"=>"<a href=\"#{BUILD + p.ant_text_output}\">#{p.mod} (#{br.deprecation_warnings})</a>", 
																"cvsTag"=>p.tag, 
																"builtAt"=>br.built_at, 
																"loc"=>br.loc, 
																"pmd"=>pmd, 
																"cpd"=>cpd 
																}]	
		}
		output << fm["footer.frag", {"time"=>Time.new}]
		output
	end
	def get_third_party_jars
		`cvs -Q -d:pserver:anonymous@cougaar.org:/cvsroot/core export -D tomorrow jars/lib/`
	end
	def glom_classpath
		ENV["CLASSPATH"] = "/usr/local/pmd-1.3/lib/pmd-1.3.jar:"
		ENV["CLASSPATH"] += ":/usr/local/pmd-1.3/lib/jaxen-core-1.0-fcs.jar:"
		ENV["CLASSPATH"] += ":/usr/local/pmd-1.3/lib/saxpath-1.0-fcs.jar:"
		ENV["CLASSPATH"] += ":/home/tom/data/cf-dashboard/#{TMP}#{BUILD}:"
		Dir.new("jars/lib/").entries.select {|x| (x == "." or x == "..") ? nil : x}.compact.each {|jar| 
			ENV["CLASSPATH"] += ":/home/tom/data/cf-dashboard/jars/lib/" + jar + ":"
		}
		end
	def build
		@projects.each {|p|
			puts "Building " + p.title + "/" + p.mod if @verbose
			p.check_out
			cmd = "ant -listener org.apache.tools.ant.XmlLogger -DXmlLogger.file=#{REPORTS}#{p.ant_xml_output} -buildfile build.xml -logfile #{BUILD}#{p.ant_text_output} -Dcore.workdir=#{TMP} -Dcore.module=#{p.mod} -Dcore.cvsTag=#{p.tag} -Dcore.cvsroot=#{CVS_ROOT} -Dcore.srcdir=#{p.srcdir} -Dcore.pmd.report=#{PMD + p.pmd_output} -Dcore.cpd.report=#{CPD + p.cpd_output} timestamp compile pmd cpd"
			`#{cmd}`

			# JavaNCSS processing
      `find #{TMP}/#{p.mod}/#{p.srcdir} -name *.java > #{TMP}/javancssfiles.txt`
			`/usr/local/javancss/bin/javancss @#{TMP}/javancssfiles.txt -xml > #{REPORTS}#{p.ncss_output}`

			# clean up
			`rm -rf #{TMP}#{p.mod}` 
		}
	end
	def prepend_working_dir(name)
		REPORTS + name
	end
	def copy_up
		`scp index.html cougaar.png #{WWW}`
		`scp pmd/* #{WWW}/pmd/`
		`scp cpd/* #{WWW}/cpd/`
		`scp build/* #{WWW}/build/`
	end
	def clean_classes
		`rm -rf #{TMP}#{BUILD}`
	end
  def parse_cpd_output(f, result)
    if !File.exists?(CPD + f) or File.size(CPD + f) < 10
      result.cpd="TBD"
      return
    end
    if File.size(CPD + f) < 50
      return
    end
    File.open(CPD + f).each {|line|
      if line["============================="] != nil
        result.cpd += 1
      end
    }
  end
  def parse_ant_build_output(filename, result)
    build_xml=REXML::Document.new File.new(filename)
    result.compile_succeeded = build_xml.elements["build"].attributes["error"].nil?
    result.deprecation_warnings = count_deprecation_warnings(build_xml)
    build_xml.elements.each("build/target/task/message[@priority='warn']") do |warning|
      if warning.text =~ /Starting/
        result.built_at = warning.text.split(/Starting build at /)[1].split(/\]\]/)[0].split(/ /)[1]
        break
      end
    end
  end
  def count_deprecation_warnings(xml)
    result = "0"
    xml.elements.each("build/target/task/message[@priority='error']") do |deprecations|
      if deprecations.text.size < 20 and deprecations.text =~ / warning/
        result = deprecations.text.split(" ")[0]
      end
    end
    return result
  end
  def parse_element(f, name)
    (REXML::Document.new(File.new(f))).elements[name].text
  end
end

if __FILE__ == $0
	ENV['JAVA_HOME']="/usr/local/java"
	ENV['ANT_HOME']="/usr/local/ant"
	ENV['PATH']="#{ENV['PATH']}:#{ENV['JAVA_HOME']}/bin:#{ENV['ANT_HOME']}/bin"

	b = Build.new(ARGV.include?("-v"))

	if ARGV.include?("-jars")
		b.get_third_party_jars
		exit
	elsif ARGV.include?("-cleanclasses")
		b.clean_classes
		exit
	elsif ARGV.include?("-copy")
		b.copy_up
		exit
	end
	
	b.add_project Project.new("Utilities","util","bootstrap","src","HEAD")
	b.add_project Project.new("Utilities","util","server","src","HEAD")
	b.add_project Project.new("Utilities","util","util","src","HEAD")
	b.add_project Project.new("Utilities","util","contract","src","HEAD")
	b.add_project Project.new("Core","core","javaiopatch","src","HEAD")
	b.add_project Project.new("Core","core","core","src","HEAD")
	b.add_project Project.new("Yellow Pages","yp","yp","src","HEAD")
	b.add_project Project.new("Web Server","webserver","webserver","src","HEAD")
	b.add_project Project.new("Web Tomcat","webserver","webtomcat","src","HEAD")
	b.add_project Project.new("Qos","qos","qos","src","HEAD")
	b.add_project Project.new("Quo","qos","quo","src","HEAD")
	b.add_project Project.new("MTS","mts","mtsstd","src","HEAD")

	b.build if ARGV.include?("-b") 
	if ARGV.include?("-r") 
		File.open("index.html", "w") {|file| file.syswrite(b.render)}
	end

	# b.add_project Project.new("General Logistics Module","glm","toolkit","src","HEAD") # need to run defrunner?
	# b.add_project Project.new("General Logistics Module","glm","glm","src","HEAD") # need to run defrunner?
	# b.add_project Project.new("Planning","planning","planning","src","HEAD") # need to run defrunner?
	# b.add_project Project.new("Aggregation Agent","aggagent","aggagent","src","HEAD") # depends on Planning, I think
	# b.add_project Project.new("Community","community","community","src","HEAD") # depends on Planning
	# b.add_project Project.new("Service Discovery","servicediscovery","servicediscovery","src","HEAD") # depends on Planning
	# b.add_project Project.new("CSMART","csmart","csmart","src","HEAD") # depends on Planning
	# b.add_project Project.new("Vishnu Client","vishnu","vishnuClient","src","HEAD")

end
