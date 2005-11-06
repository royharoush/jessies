#!/bin/bash

# It's important that your server's svn(1) be a wrapper like this:
# 
# $ cat `type -p svn`
# #!/bin/sh
# umask 002
# /usr/bin/svn.orig "$@"
# $
#
# It's not possible to work around ownership/permissions problems in this
# script, because each check-in risks messing things up unless the umask is
# always set appropriately. Subversion itself does nothing to help you with
# this.

if [ $# != 2 ]; then
    echo "Usage: $0 <username> <project-name>"
    exit 1
fi

# Hard-coding @jessies.org might seem like a mistake, but it's just to make
# it clear that the rest of this script still makes assumptions about
# directory layout and the like that you will need to change if you change
# this line.
svn_user_and_host=$1@jessies.org
project_name=$2

projects_dir=~/Projects

if [ -d $projects_dir/$project_name ]; then
    echo "Project '$project_name' already exists!"
    exit 1
fi
if [ ! -f $projects_dir/edit/COPYING ]; then
    echo "Couldn't find a copy of the GPL!"
    exit 1
fi

echo "Creating new project '$project_name'..."

mkdir -p /tmp/$$
cd /tmp/$$

echo "Creating directories..."
mkdir -p $project_name
mkdir -p $project_name/src

echo "Creating Makefile..."
cat > $project_name/Makefile <<EOF
include ../salma-hayek/universal.make
EOF

echo "Adding GPL..."
cp $projects_dir/edit/COPYING $project_name/COPYING

echo "Creating a new Subversion repository..."
ssh $svn_user_and_host svnadmin create /home/software/svnroot/$project_name
ssh $svn_user_and_host ln -s /home/software/checked-out/salma-hayek/post-commit /home/software/svnroot/$project_name/hooks
echo "Making the initial import..."
svn import $project_name svn+ssh://$svn_user_and_host/home/software/svnroot/$project_name -m "New project, $project_name."
echo "Checking back out..."
svn co svn+ssh://$svn_user_and_host/home/software/svnroot/$project_name $projects_dir/$project_name
cd $projects_dir/$project_name

echo "Telling Subversion to ignore generated files..."
svn propset svn:ignore "ChangeLog
ChangeLog.html
classes
.generated
$project_name.jar" .
echo "Getting Subversion to commit that change..."
svn update
echo "Prompting you to manually commit that change..."
checkintool

echo "Done!"
exit 0
