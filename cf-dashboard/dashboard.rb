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
  def preamble
    @repo + "_" + @mod + "_" + @tag
  end
end

class BuildResult
	attr_accessor :compile_succeeded, :deprecation_warnings, :built_at
end

class Build 
	CVS_ROOT = ":pserver:anonymous@cougaar.org:/cvsroot/"
	TMP = "working/"
	REPORTS = "reports/"
	def initialize()
		@projects = []
   	Dir.mkdir(TMP) unless File.exist? TMP
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
			output << fm["row.frag", {"repository"=>p.repo, "module"=>p.mod, "cvsTag"=>p.tag, "builtAt"=>br.built_at}]	
		}
		output << fm["footer.frag"]
		output
	end
	def get_third_party_jars
	end
	def build
		get_third_party_jars()
		@projects.each {|p|
			cmd = "ant -v -listener org.apache.tools.ant.XmlLogger -DXmlLogger.file=#{REPORTS}#{p.ant_xml_output} -buildfile build.xml -logfile #{REPORTS}#{p.ant_text_output} -Dcore.workdir=#{TMP} -Dcore.repository=#{p.repo} -Dcore.module=#{p.mod} -Dcore.cvsTag=#{p.tag} -Dcore.cvsroot=#{CVS_ROOT} -Dcore.srcdir=#{p.srcdir} checkout compile "
			puts cmd
			puts `#{cmd}`
		}
	end
	def clean		
		`rm -rf TMP`
	end
	def prepend_working_dir(name)
		REPORTS + name
	end
  def parse_ant_build_output(filename, result)
    build_xml=REXML::Document.new File.new(filename)
    result.compile_succeeded = build_xml.elements["build"].attributes["error"].nil?
    result.deprecation_warnings = count_deprecation_warnings(build_xml)
    build_xml.elements.each("build/target/task/message[@priority='warn']") do |warning|
			puts warning
      if warning.text =~ /Starting/
        result.built_at = warning.text.split("Starting build at ")[1].split("]]")[0].split(" ")[1]
        break
      end
    end
  end
  def count_deprecation_warnings(xml)
    result = "0"
    xml.elements.each("build/target/task/message[@priority='error']") do |deprecations|
      if deprecations.text.size < 20 and deprecations.text =~ " warning"
        result = deprecations.text.split(" ")[0]
      end
    end
    return result
  end
end

if __FILE__ == $0
	b = Build.new
	b.add_project Project.new("core","javaiopatch","src","B10_4")
	b.build if ARGV.include?("-b") 
	puts b.render if ARGV.include?("-r") 
end
