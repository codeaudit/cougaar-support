#!/usr/local/bin/ruby

Dir.chdir("/home/gforge/cronjobs/")
`cvs -d:pserver:anonymous@cougaar.org:/cvsroot/cougaar co errata`
`cp errata/cougaar1046/errata.html /var/www/gforge-3.0/www/`
`rm -rf errata`
