#!/usr/local/bin/ruby

require 'ikko.rb'
require 'fileutils'
require 'rexml/document'

class Project
	attr_reader :repo, :mod, :srcdir, :tag, :title, :uses_defrunner
	def initialize(title,repo,mod,srcdir,tag,uses_defrunner)
		@title = title
		@repo = repo
		@mod = mod
		@srcdir = srcdir
		@tag = tag
		@uses_defrunner = uses_defrunner
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

class ProjectGroup
	attr_accessor :projects
	def initialize	
		@projects = []
	end
	def add_project(p)
		@projects << p
	end
	def delete_all_but_first
		@projects.delete_if {|a| @projects.index(a) > 3 }
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

class Summary
	def initialize
		@build_results = []
	end
	def add_build_result(br)
		@build_results << br
	end
	def loc
		sum = 0
		@build_results.each {|x| sum += x.loc.to_i }
		return sum	
	end
end

class Build 
	CVS_ROOT = ":pserver:anonymous@cougaar.org:/cvsroot/"
	BUILD_ROOT = "/home/tom/data/cf-dashboard/"
	TMP = "working/"
	PMD = "pmd/"
	CPD = "cpd/"
	BUILD = "build/"
	REPORTS = "reports/"
	JARS = "jars/lib/"
	WWW = "tom@cougaar.org:/var/www/gforge-projects/support/build/"
	def initialize(verbose, pg)
		@pg = pg
		@verbose = verbose
		ENV['JAVA_HOME']="/usr/local/java"
		ENV['ANT_HOME']="/usr/local/ant"
		ENV['ANT_OPTS']="-Xmx1024m"
		ENV['PATH']="#{ENV['PATH']}:#{ENV['JAVA_HOME']}/bin:#{ENV['ANT_HOME']}/bin"

   	Dir.mkdir(TMP) unless File.exist? TMP
   	Dir.mkdir(CPD) unless File.exist? CPD
   	Dir.mkdir(PMD) unless File.exist? PMD
   	Dir.mkdir(BUILD) unless File.exist? BUILD
   	Dir.mkdir(TMP + "build") unless File.exist? TMP + "build"
		FileUtils.mkdir_p(TMP + "build/") unless File.exists?(TMP + "build/")
		FileUtils.mkdir_p(JARS) unless File.exists?(JARS)
   	Dir.mkdir(REPORTS) unless File.exist?(REPORTS)
		glom_classpath
	end
	def get_third_party_jars
		`rm -rf jars/`
		`cvs -Q -d#{CVS_ROOT}core export -D tomorrow #{Build::JARS}`
	end
	def glom_classpath
		ENV["CLASSPATH"] = "/usr/local/pmd-1.5/lib/pmd-1.5.jar:"
		ENV["CLASSPATH"] += ":/usr/local/pmd-1.5/lib/jaxen-core-1.0-fcs.jar:"
		ENV["CLASSPATH"] += ":/usr/local/pmd-1.5/lib/saxpath-1.0-fcs.jar:"
		ENV["CLASSPATH"] += ":" + BUILD_ROOT + TMP + ":" + BUILD
		Dir.new(JARS).entries.select {|x| (x == "." or x == "..") ? nil : x}.compact.each {|jar| 
			ENV["CLASSPATH"] += ":" + BUILD_ROOT + JARS + jar + ":"
		}
		end
	def build
		@pg.projects.each {|p|
			puts "Building " + p.title + "/" + p.mod if @verbose
			p.check_out
			defrunner = p.uses_defrunner ? "defrunner" : ""
			cmd = "ant -listener org.apache.tools.ant.XmlLogger "
			cmd += "-DXmlLogger.file=#{REPORTS}#{p.ant_xml_output} "
			cmd += "-buildfile build.xml -logfile #{BUILD}#{p.ant_text_output} "
			cmd += "-Dcore.workdir=#{TMP} "
			cmd += "-Dcore.module=#{p.mod} "
			cmd += "-Dcore.cvsTag=#{p.tag} "
			cmd += "-Dcore.cvsroot=#{CVS_ROOT} "
			cmd += "-Dcore.srcdir=#{p.srcdir} "
			cmd += "-Dcore.pmd.report=#{PMD + p.pmd_output} "
			cmd += "-Dcore.cpd.report=#{CPD + p.cpd_output} "
			cmd += "timestamp #{defrunner} compile pmd cpd"
			`#{cmd}`

			# JavaNCSS processing
      `find #{TMP}/#{p.mod}/#{p.srcdir} -name *.java > #{TMP}/javancssfiles.txt`
			`/usr/local/javancss/bin/javancss @#{TMP}/javancssfiles.txt -xml > #{REPORTS}#{p.ncss_output}`

			# Prepend PMD report with some metadata
			pmd_text = ""
			File.read(BUILD_ROOT + PMD + p.pmd_output).each {|x| pmd_text << x } unless !File.exist?(BUILD_ROOT + PMD + p.pmd_output)
			pmd_header = "# Date: " + Time.now.to_s + "<br>"
			pmd_header = pmd_header + "# Module: " + p.mod + "<br>"
			pmd_header = pmd_header + "# Repository: " + CVS_ROOT + p.repo + "<br>"
			pmd_header = pmd_header + "# Tag: " + p.tag + "<br>"
			pmd_header = pmd_header + "# Rulesets: unusedcode.xml<br>"
			File.open(BUILD_ROOT + PMD + p.pmd_output, "w") {|file| file.syswrite(pmd_header + pmd_text)}
			
			# clean up
			cmd = "rm -rf " + TMP + p.mod
			`#{cmd}` 
			FileUtils.mkdir_p(TMP + "build/") if p.mod == "build" # tricky tricky!
		}
	end
	def render
		fm=Ikko::FragmentManager.new
    fm.base_path="./"
    output=fm["header.frag"]
		summary = Summary.new
		@pg.projects.each {|p| 	
			puts "Rendering " + p.title + "/" + p.mod if @verbose
			br = BuildResult.new
			parse_ant_build_output(prepend_working_dir(p.ant_xml_output),br)
			br.loc = parse_element(REPORTS + "/" + p.ncss_output, "javancss/ncss")
			br.parse_pmd_output(p.pmd_output)
      pmd="<a href=\"#{PMD}#{p.pmd_output}\">#{br.pmd.to_s}</a>" unless br.pmd == 0
			parse_cpd_output(p.cpd_output, br)
      cpd="<a href=\"#{CPD}#{p.cpd_output}\">#{br.cpd}</a>" if br.cpd != 0
			output << fm["row.frag", {"title"=>p.title, 		
																"color"=>br.compile_succeeded ? "#00FF00" : "red", 
																"module"=>"<a href=\"#{BUILD + p.ant_text_output}\">#{p.mod} (#{br.deprecation_warnings})</a>", 
																"cvsTag"=>p.tag, 
																"builtAt"=>br.built_at, 
																"loc"=>br.loc, 
																"pmd"=>pmd, 
																"cpd"=>cpd 
																}]	
			summary.add_build_result(br)
		}
		output << fm["footer.frag", {"time"=>Time.new, "loc"=>summary.loc}]
		output
	end
	def prepend_working_dir(name)
		REPORTS + name
	end
	def copy_up
		`scp *.html cougaar.png #{WWW}`
		`scp pmd/* #{WWW}/pmd/`
		`scp cpd/* #{WWW}/cpd/`
		`scp build/* #{WWW}/build/`
	end
	def clean_classes
		`rm -rf #{TMP}#{BUILD}`
	end
  def parse_cpd_output(f, result)
    if !File.exists?(CPD + f) or File.size(CPD + f) < 50
      return
    end
    File.open(CPD + f).each {|line| result.cpd += 1 if line["============================="] != nil }
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
	pg = ProjectGroup.new
	pg.add_project Project.new("Build","build","build","src","HEAD",false)
	pg.add_project Project.new("Utilities","util","bootstrap","src","HEAD",false)
	pg.add_project Project.new("Utilities","util","server","src","HEAD",false)
	pg.add_project Project.new("Utilities","util","util","src","HEAD",false)
	pg.add_project Project.new("Utilities","util","contract","src","HEAD",false)
	pg.add_project Project.new("Core","core","javaiopatch","src","HEAD",false)
	pg.add_project Project.new("Core","core","core","src","HEAD",false)
	pg.add_project Project.new("Yellow Pages","yp","yp","src","HEAD",false)
	pg.add_project Project.new("Web Server","webserver","webserver","src","HEAD",false)
	pg.add_project Project.new("Web Tomcat","webserver","webtomcat","src","HEAD",false)
	pg.add_project Project.new("MTS","mts","mtsstd","src","HEAD",false)
	pg.add_project Project.new("Qos","qos","qos","src","HEAD",false)
	pg.add_project Project.new("Quo","qos","quo","src","HEAD",false)
	pg.add_project Project.new("Planning","planning","planning","src","HEAD",true)
	pg.add_project Project.new("Aggregation Agent","aggagent","aggagent","src","HEAD",false) # depends on Planning defs
	pg.add_project Project.new("Community","community","community","src","HEAD", false) # depends on Planning defs
	pg.add_project Project.new("General Logistics Module","glm","toolkit","src","HEAD", false)
	pg.add_project Project.new("General Logistics Module","glm","glm","src","HEAD",true) # depends on Planning defs
	pg.add_project Project.new("CSMART","csmart","csmart","src","HEAD",false) # depends on Planning defs
	pg.add_project Project.new("Vishnu Client","vishnu","vishnuClient","src","HEAD", false)
	pg.add_project Project.new("Service Discovery","servicediscovery","servicediscovery","src","HEAD",false) # depends on Planning, glm, jena (?)

	pg.delete_all_but_first if ARGV.include?("-one")

	b = Build.new(ARGV.include?("-v"), pg)

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

	b.build if ARGV.include?("-b") 
	File.open("index.html", "w") {|file| file.syswrite(b.render)}  if ARGV.include?("-r")
end
