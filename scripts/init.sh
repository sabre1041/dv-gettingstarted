#!/bin/sh 
DEMO="JBoss Data Virtualization Getting Started Demo" 
AUTHORS="Kenny Peeples"
PROJECT="git@github.com:jbossdemocentral/dv-gettingstarted.git"
PRODUCT="JBoss DV Demo"
INSTALL_DIR=../target
JBOSS_HOME_DV=$INSTALL_DIR/dv6.2/EAP-6.4.0
SERVER_BIN_DV=$JBOSS_HOME_DV/bin
SERVER_CONF_DV=$JBOSS_HOME_DV/standalone/configuration/
SRC_DIR=../software
DV_SUPPORT_DIR=../support
PRJ_DIR=../projects
DV=jboss-dv-installer-6.2.0.redhat-2.jar
DV_VERSION=6.2.0
EAP=jboss-eap-6.4.0-installer.jar
EAP_VERSION=6.4.0
EAP_PATCH=jboss-eap-6.4.3-patch.zip

# wipe screen.
clear 

echo  
echo "Setting up the ${DEMO}"  
echo    
echo "brought to you by,"   
echo "  ${AUTHORS}"
echo 
echo "  ${PROJECT}"
echo

command -v mvn -q >/dev/null 2>&1 || { echo >&2 "Maven is required but not installed yet... aborting."; exit 1; }

# make some checks first before proceeding.	
if [ -r $SRC_DIR/$DV ] || [ -L $SRC_DIR/$DV ]; then
	    echo JBoss DV product sources present...
		echo
else
		echo Need to download $DV package from the Customer Portal 
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

# make some checks first before proceeding.	
if [ -r $SRC_DIR/$EAP ] || [ -L $SRC_DIR/$EAP ]; then
	    echo JBoss EAP product sources present...
		echo
else
		echo Need to download $EAP package from the Customer Portal 
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

if [ -r $SRC_DIR/$EAP_PATCH ] || [ -L $SRC_DIR/$EAP_PATCH ]; then
	    echo JBoss EAP product patch present...
		echo
else
		echo Need to download $EAP_PATCH package from the Customer Portal 
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

# Remove JBoss product installation if exists.
if [ -x $INSTALL_DIR ]; then
	echo "  - existing JBoss product installation detected..."
	echo
	echo "  - removing existing JBoss product installation..."
	echo
	rm -rf $INSTALL_DIR
fi

echo
echo "Starting JBoss EAP install..." 
echo
java -jar $SRC_DIR/$EAP $DV_SUPPORT_DIR/eap64-installer.xml

if [ $? -ne 0 ]; then
	echo
	echo "Error occurred during JBoss EAP installation!"
	exit
fi

echo
echo "Installed JBoss EAP server..."
echo

echo "Starting JBoss EAP Server..."
echo

#  start server install the eap 6.4.3 patch
$JBOSS_HOME_DV/bin/standalone.sh >>console.log &

sleep 10

tail -f $JBOSS_HOME_DV/standalone/log/server.log | grep -m 1 'started in' | xargs echo '' >> $JBOSS_HOME_DV/standalone/log/server.log

echo
echo "Started JBoss EAP server"

echo "Installing JBoss EAP 6.4.3 Patch ..."

# install patch
$JBOSS_HOME_DV/bin/jboss-cli.sh --command="patch apply $SRC_DIR/jboss-eap-6.4.3-patch.zip"

if [ $? -ne 0 ]; then
	echo
	echo "Error occurred during JBoss EAP patch installation!"
	exit
fi

echo "Installed JBoss EAP patch..."
echo

echo
echo "Shutting down JBoss EAP server..."

$JBOSS_HOME_DV/bin/jboss-cli.sh --connect command=:shutdown

echo
echo "Shutdown JBoss EAP server..."
echo

if [ $? -ne 0 ]; then
	echo
	echo "Error occurred during JBoss EAP shutdown!"
	exit
fi

# Run JBoss DV installer.
echo "Installing JBoss DV now..."
echo
java -jar $SRC_DIR/$DV $DV_SUPPORT_DIR/dv62-installer.xml

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during JBoss DV installation!
	exit
fi

echo
echo "Post JBoss DV install configuration..."
echo

echo
echo "  - install teiid security files..."
echo
cp $DV_SUPPORT_DIR/application* $SERVER_CONF_DV

echo
echo "  - move data files..."
echo
cp -R $DV_SUPPORT_DIR/data/* $JBOSS_HOME_DV/standalone/data

echo
echo "  - move virtual database..."
echo
cp -R $DV_SUPPORT_DIR/vdb $JBOSS_HOME_DV/standalone/deployments

echo "  - setting up dv standalone.xml configuration adjustments..."
echo
cp $DV_SUPPORT_DIR/dv62-standalone.xml $SERVER_CONF_DV/standalone.xml

echo "  - cleaning up install log..."
echo
rm console.log

# Final instructions to user to start and run demo.                                                                  
echo
echo "See README.md for any additional steps"                   
echo "$DEMO Setup Complete."
echo

