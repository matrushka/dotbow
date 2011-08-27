#!/usr/bin/env bash

if [[ `whoami` != "root" ]]; then
echo "This script must be run as root; use sudo"
  exit
fi

echo "Installing Bow Launcher";

# copy PLIST and (re)install it
SERVICE_NAME = "com.bow.bowd"
PLIST_FILE = "$SERVICE_NAME.plist"
sudo cp $PLIST_FILE /System/Library/LaunchDaemons/.
sudo chown root:wheel /System/Library/LaunchDaemons/$PLIST_FILE
sudo launchctl stop $SERVICE_NAME
sudo launchctl unload /System/Library/LaunchDaemons/$PLIST_FILE
sudo launchctl load /System/Library/LaunchDaemons/$PLIST_FILE
sudo launchctl start $SERVICE_NAME

echo "FINISHED";