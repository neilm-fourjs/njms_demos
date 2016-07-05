#!/bin/bash

# Sample script to run the application

cd bin300

export FGLRESOURCEPATH=../etc
export FGLIMAGEPATH=../pics:../pics/image2font.txt
export DBNAME=fjs_demos
export BASE=..
export HOSTNAME=`uname -n`
export REPORTDIR=../etc/
export GREDIR=/opt/fourjs/gre300
export FGLLDPATH=$GREDIR/lib
export TIMELOG=/tmp/time_ssh.log

echo HOST=$HOSTNAME

#env | sort  > env.log
fglrun $1 2> $1.err
