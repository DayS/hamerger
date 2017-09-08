#!/bin/bash
#Forked from https://gist.github.com/jlazic/e65f5bda141ffaed5640 in order to use hameger.js for config file generation and fix an issue during diff check

#Requirements: diffcolor
#Optional: etckeeper

#This script concatenates multiple files of haproxy configuration into
#one file, and than checks if monolithic config contains errors. If everything is
#OK with new config script will write new config to $CURRENTCFG and reload haproxy
#Also, script will commit changes to etckeeper, if you don't use etckeeper you
#should start using it.
#Script assumes following directory structure:
#/etc/haproxy/conf.d/
#├── 00-global.cfg
#├── 15-lazic.cfg
#├── 16-togs.cfg
#├── 17-svartberg.cfg
#├── 18-home1.cfg.disabled
#└── 99-globalend.cfg
#Every site has it's own file, so you can disable site by changing
#it's file extension, or appending .disabled, like I do.


CURRENTCFG=/etc/haproxy/haproxy.cfg
BACKUPCFG=/etc/haproxy/haproxy.cfg.bck
NEWCFG=/tmp/haproxy.cfg.tmp
CONFIGDIR=/etc/haproxy/conf.d

DIR=`dirname $0`

echo "Compiling *.cfg files from $CONFIGDIR"
$DIR/hamerger.js $CONFIGDIR --verbose --output $NEWCFG

echo "Differences between current and new config"
colordiff -s -U 3 $CURRENTCFG $NEWCFG
if [ $? -ne 0 ]; then
    echo "You should make some changes first :)"
    exit 1 #Exit if old and new configuration are the same
fi

echo -e "Checking if new config is valid..."
haproxy -c -f $NEWCFG
if [ $? -eq 0 ]; then
    echo "Check if there are some warnings in new configuration."
    read -p "Should I copy new configuration to $CURRENTCFG and reload haproxy? [y/N]" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        if ! hash etckeeper 2>/dev/null; then
            echo "Backup current config version in $BACKUPCFG..."
            cat $CURRENTCFG > $BACKUPCFG
        fi

        echo " "
        echo "Working..."
        cat $NEWCFG > $CURRENTCFG

        if hash etckeeper 2>/dev/null; then
            echo "Versionning new haproxy config..."
            etckeeper commit -m "Updating haproxy configuration"
        fi

        echo "Reloading haproxy..."
        service haproxy reload
    fi
else
    echo "There are errors in new configuration, please fix them and try again."
    exit 1
fi