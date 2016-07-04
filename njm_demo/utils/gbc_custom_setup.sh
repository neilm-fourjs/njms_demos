#!/bin/bash
# Script to attempt to setup GBC development environment

# Arg1: custom folder name, default is njm-js
# Arg2: GBC version for base - default is gwc-js-1.00.19

CUSTDIR=${1:njm-js}
VER=${2:-gwc-js-1.00.19}

GASDIR=$(pwd)
DTE=$( date +'%Y%m%d%H%M%S')

if [ ! -e $CUSTDIR ]; then
	echo $( date +'%Y%m%d%H%M%S') "mkdir $CUSTDIR"
	mkdir $CUSTDIR
fi

cd $CUSTDIR

if [ ! -e $VER ]; then
	echo $( date +'%Y%m%d%H%M%S') " unzip $VER ..."
	unzip ../tpl/fjs-$VER*
	if [ $? -ne 0 ]; then
		exit 1
	fi
fi

cd $VER

NODEJS_MJVER=$(node --version | cut -c2)
if [ $? -ne 0 ]; then
	echo "Failed to get node version!"
	exit 1
fi
if [ $NODEJS_MJVER -lt 4 ]; then
	echo "node js major version is too low: $NODEJS_MJVER must be => 4"
	exit 1
fi
NODEJS_MNVER=$(node --version | cut -c4)
if [ $NODEJS_MNVER -lt 2 ]; then
	echo "node js minor version is too low:  $NODEJS_MNVER must be => 2"
	exit 1
fi
echo "Node JS major versions is " $NODEJS_MJVER.$NODEJS_MNVER

if [ ! -e npm_install.ok ]; then
	echo $( date +'%Y%m%d%H%M%S') " npm install ..."
	npm install 2>&1 | tee npm_install.$DTE.out
	if [ $? -ne 0 ]; then
		echo "Failed!"
		exit 1
	else
		touch npm_install.ok
	fi
fi

if [ ! -e npm_install_grunt_cli.ok ]; then
	echo $( date +'%Y%m%d%H%M%S') " npm install -g grunt-cli ..."
	npm install -g grunt-cli 2>&1 | tee npm_install_grunt_cli.$DTE.out
	if [ $? -ne 0 ]; then
		echo "Failed!"
		exit 1
	else
		touch npm_install_grunt_cli.ok
	fi
fi

if [ ! -e npm_install_bower.ok ]; then
	echo $( date +'%Y%m%d%H%M%S') " npm install -g bower ..."
	npm install -g bower 2>&1 | tee npm_install_bower.$DTE.out
	if [ $? -ne 0 ]; then
		echo "Failed!"
		exit 1
	else
		touch npm_install_bower.ok
	fi
fi

if [ ! -e grunt_deps.ok ]; then
	echo $( date +'%Y%m%d%H%M%S') " grunt deps ..."
	grunt deps 2>&1 | tee grunt_deps.$DTE.out
	if [ $? -ne 0 ]; then
		echo "Failed!"
		exit 1
	else
		touch grunt_deps.ok
	fi
fi

echo $( date +'%Y%m%d%H%M%S') " grunt ..."
grunt 2>&1 | tee grunt.$DTE.out
if [ $? -ne 0 ]; then
	echo "Failed!"
	exit 1
fi

cd $GASDIR/web
if [ ! -e $CUSTDIR ]; then
	echo $( date +'%Y%m%d%H%M%S') " Adding symbolic link for $CUSTDIR in $GAS/web ..."
	ln -s ../$CUSTDIR/$VER/dist/web/ $CUSTDIR
fi

echo $( date +'%Y%m%d%H%M%S') "Finished Okay"
