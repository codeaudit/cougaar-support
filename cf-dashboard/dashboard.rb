#!/usr/local/bin/ruby

require 'ikko.rb'
require 'rexml/document'

class Project
	attr_reader :repo, :mod, :srcdir, :tag
	def initialize(repo,mod,srcdir,tag)
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
    preamble + "_pmd.txt"
  end
  def cpd_output
    preamble + "_cpd.txt"
  end
  def preamble
    @repo + "_" + @mod + "_" + @tag
  end
end

class BuildResult
	attr_accessor :compile_succeeded, :deprecation_warnings, :built_at, :loc, :pmd, :cpd
	def initialize 
		@pmd = 0
		@cpd = 0
	end
end

class Build 
	CVS_ROOT = ":pserver:anonymous@cougaar.org:/cvsroot/"
	TMP = "working/"
	PMD = "pmd/"
	CPD = "cpd/"
	BUILD = "build/"
	REPORTS = "reports/"
	def initialize()
		@projects = []
   	Dir.mkdir(TMP) unless File.exist? TMP
   	Dir.mkdir(CPD) unless File.exist? CPD
   	Dir.mkdir(PMD) unless File.exist? PMD
   	Dir.mkdir(BUILD) unless File.exist? BUILD
   	Dir.mkdir(TMP + "build") unless File.exist? TMP + "build"
   	Dir.mkdir(REPORTS) unless File.exist?(REPORTS)
	end
	def add_project(p)
		@projects << p
	end	
	def render
		fm=Ikko::FragmentManager.new
    fm.base_path="./"
    output=fm["header.frag"]
		@projects.each {|p| 
			br = BuildResult.new
			parse_ant_build_output(prepend_working_dir(p.ant_xml_output),br)
			br.loc = parse_element(REPORTS + "/" + p.ncss_output, "javancss/ncss")
			parse_pmd_output(p.pmd_output, br)
      pmd="<a href=\"#{PMD}#{p.pmd_output}\">#{br.pmd.to_s}</a>" unless br.pmd == 0
			parse_cpd_output(p.cpd_output, br)
      if br.cpd == 0
      	cpd="0"
      elsif br.cpd == "TBD"
        cpd="TBD"
      else
        cpd="<a href=\"#{CPD}/#{p.cpd_output}\">#{br.cpd}</a>"
      end
			output << fm["row.frag", {"repository"=>p.repo, 		
																"color"=>br.compile_succeeded ? "#00FF00" : "red", 
																"module"=>"<a href=\"#{BUILD + p.ant_text_output}\">#{p.mod} (#{br.deprecation_warnings})</a>", 
																"cvsTag"=>p.tag, 
																"builtAt"=>br.built_at, 
																"loc"=>br.loc, 
																"pmd"=>pmd, 
																"cpd"=>cpd 
																}]	
		}
		output << fm["footer.frag"]
		output
	end
	def get_third_party_jars
	end
	def build
		get_third_party_jars
		@projects.each {|p|
			cmd = "ant -listener org.apache.tools.ant.XmlLogger -DXmlLogger.file=#{REPORTS}#{p.ant_xml_output} -buildfile build.xml -logfile #{BUILD}#{p.ant_text_output} -Dcore.workdir=#{TMP} -Dcore.repository=#{p.repo} -Dcore.module=#{p.mod} -Dcore.cvsTag=#{p.tag} -Dcore.cvsroot=#{CVS_ROOT} -Dcore.srcdir=#{p.srcdir} -Dcore.pmd.report=#{PMD + p.pmd_output} -Dcore.cpd.report=#{CPD + p.cpd_output} timestamp checkout compile pmd cpd"
			`#{cmd}`

			# JavaNCSS processing
      `find #{TMP}/#{p.mod}/#{p.srcdir} -name *.java > #{TMP}/javancssfiles.txt`
			`/usr/local/javancss/bin/javancss @#{TMP}/javancssfiles.txt -xml > #{REPORTS}#{p.ncss_output}`
		}
	end
	def clean		
		`rm -rf TMP`
	end
	def prepend_working_dir(name)
		REPORTS + name
	end
	def copy_up
		`scp index.html cougaar.png tom@cougaar.org:/var/www/gforge-projects/support/build/`
		`scp pmd/* tom@cougaar.org:/var/www/gforge-projects/support/build/pmd/`
		`scp cpd/* tom@cougaar.org:/var/www/gforge-projects/support/build/cpd/`
		`scp build/* tom@cougaar.org:/var/www/gforge-projects/support/build/build/`
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
	def parse_pmd_output(f,br)
    if !File.exists?(PMD + f) or File.size(PMD + f) < 12
      return
    end
    File.new(PMD + f).each("<td ") {|x| count += 1}
    br.pmd=(count/4) unless count==0
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
	ENV["CLASSPATH"] = "/usr/local/pmd-1.3/lib/pmd-1.3.jar:"
	ENV["CLASSPATH"] += ":/usr/local/pmd-1.3/lib/jaxen-core-1.0-fcs.jar:"
	ENV["CLASSPATH"] += ":/usr/local/pmd-1.3/lib/saxpath-1.0-fcs.jar:"
	b = Build.new
	b.add_project Project.new("core","javaiopatch","src","B10_4")
	b.build if ARGV.include?("-b") 
	puts b.render if ARGV.include?("-r") 
	b.copy_up if ARGV.include?("-copy") 
end
