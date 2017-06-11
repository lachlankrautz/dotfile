#!/usr/bin/env bash

if [ ! -d /opt ]; then
    echo "Missing install dir \"/opt\""
    exit 1
fi

if [ -d /opt/dotfile ]; then
    echo "Uninstalling old version"
    rm -rf /opt/dotfile
fi

# Get files
cd /opt
git clone --depth=1 --branch=master git@github.com:lachlankrautz/dotfile
if cd dotfile; then
    rm -rf .git
    rm .gitignore
    chmod 755 bin/dotfile
else
    exit 1
fi

if [ -f /usr/bin/dotfile ]; then
    rm /usr/bin/dotfile
fi
ln -s /opt/dotfile/bin/dotfile /usr/bin/dotfile

dotfile
