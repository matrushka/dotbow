#!/usr/bin/env bash

echo "Installing .bow from git"
git clone git://github.com/matrushka/dotbow.git $HOME/.bow

if [ uname == "Darwin" ]; then
	echo "Setting up LaunchAgent"
	# copy PLIST and (re)install it
	SERVICE_NAME = "com.bow.bowd"
	PLIST_FILE = "$SERVICE_NAME.plist"
	# Place user agent file
	cp $PLIST_FILE $HOME/LaunchAgents/.
	launchctl stop $SERVICE_NAME
	launchctl unload $HOME/LaunchAgents/$PLIST_FILE
	launchctl load $HOME/LaunchAgents/$PLIST_FILE
	launchctl start $SERVICE_NAME
else
	echo ""
fi

echo "FINISHED";