#!/usr/local/bin/ruby

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

class Build 
	CVS_ROOT = ":pserver:anonymous@cougaar.org:/cvsroot/"
	TMP = "tmp/"
	def initialize(reports_dir)
		@projects = []
		@reports_dir = reports_dir
   	Dir.mkdir(TMP) unless File.exist? TMP
   	Dir.mkdir(TMP + "build")
   	Dir.mkdir(@reports_dir) unless File.exist?(@reports_dir)
	end
	def add_project(p)
		@projects << p
	end
	def get_third_party_jars
	end
	def build
		get_third_party_jars()
		@projects.each {|p|
			cmd = "ant -v -listener org.apache.tools.ant.XmlLogger -DXmlLogger.file=#{@reports_dir}#{p.ant_xml_output} -buildfile build.xml -logfile #{@reports_dir}#{p.ant_text_output} -Dcore.workdir=#{TMP} -Dcore.repository=#{p.repo} -Dcore.module=#{p.mod} -Dcore.cvsTag=#{p.tag} -Dcore.cvsroot=#{CVS_ROOT} -Dcore.srcdir=#{p.srcdir} checkout compile "
			puts cmd
			puts `#{cmd}`
		}
	end
	def clean		
		`rm -rf TMP`
	end
end

if __FILE__ == $0
	b = Build.new("reports/")
	b.add_project Project.new("core","javaiopatch","src","B10_4")
	b.build
end
