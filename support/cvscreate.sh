#!/bin/sh
echo ""
echo "CVS Repository Tool"
echo "(c)1999 SourceForge Development Team"
echo "Released under the GPL, 1999"
echo ""

# if no arguments, print out help screen
if test $# -lt 2; then 
	echo "usage:"
	echo "  cvscreate.sh [repositoryname] [initialusername] "
	echo ""
	exit 1 
fi

# make sure this repository doesn't already exist
if [ -d /cvsroot/$1 ] ; then
	echo "$1 already exists."
	echo ""
	exit 1
fi

# first create the repository
mkdir /cvsroot/$1
cvs -d/cvsroot/$1 init

# touch history file to get things started
touch /cvsroot/$1/CVSROOT/history

# copy over some stuff from the prototype repository
cp 	/cvsroot/prototype/CVSROOT/loginfo* \
	/cvsroot/prototype/CVSROOT/readers* \
	/cvsroot/prototype/CVSROOT/passwd* \
	/cvsroot/prototype/CVSROOT/cvswrappers* \
	/cvsroot/prototype/CVSROOT/writers* \
	/cvsroot/$1/CVSROOT/

# make it group writable
chmod -R 775 /cvsroot/$1

# set group ownership
chown -R $2:$1 /cvsroot/$1

# set sticky bit
chmod -R g+s /cvsroot/$1


