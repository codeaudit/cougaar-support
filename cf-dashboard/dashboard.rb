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
	def initialize(reports_dir)
		@projects = []
		@reports_dir = reports_dir
		@working_dir="tmp_" + Time.now.usec.to_s + "/"
   	Dir.mkdir(@working_dir)
   	Dir.mkdir(@working_dir + "build")
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
			cmd = "ant -v -listener org.apache.tools.ant.XmlLogger -DXmlLogger.file=#{@reports_dir}#{p.ant_xml_output} -buildfile build.xml -logfile #{@reports_dir}#{p.ant_text_output} -Dcore.workdir=#{@working_dir} -Dcore.repository=#{p.repo} -Dcore.module=#{p.mod} -Dcore.cvsTag=#{p.tag} -Dcore.cvsroot=#{CVS_ROOT} checkout"
			puts cmd
			puts `#{cmd}`
		}
	end
	def clean		
		`rm -rf #{working_dir}`
	end
end

if __FILE__ == $0
	b = Build.new("reports/")
	b.add_project Project.new("core","core","src","B10_4")
	b.build
end
