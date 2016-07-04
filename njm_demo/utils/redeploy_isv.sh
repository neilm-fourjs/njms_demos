#!/bin/bash

# Example script to re-deploy a gar file to a gpaas cloud machine
# assuming the gar is in /tmp/

APP=njm_demo
GAS=/opt/fourjs/gas300
XCF=isv_as300.xcf

# Find last gar for the APP name.
FNAME=$(ls -1rt /tmp/$APP*.gar | tail -1)

# Make link to the app-ver.gar file to app.gar
rm $(APP).gar 
ln -s $FNAME $(APP).gar

# Set gas environ
. $GAS/envas

echo "Remove previous ..."
gasadmin -f $GAS/etc/$XCF --disable-archive $APP
gasadmin -f $GAS/etc/$XCF --undeploy-archive $APP

echo "Deploy new ..."
gasadmin -f $GAS/etc/$XCF --deploy-archive $(APP).gar
gasadmin -f $GAS/etc/$XCF --enable-archive $APP

