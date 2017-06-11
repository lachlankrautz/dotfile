#!/usr/bin/env bash

SUDO_CMD=""
if [[ "${OS}" =~ .*indows.* ]]; then
    SUDO_CMD="sudo"
else
    if [ "${EUID}" -eq 0 ]; then
        echo "Do not install as root; user home dir is needed"
        exit 1
    fi
fi

if [ ! -d /opt ]; then
    echo "Missing install dir \"/opt\""
    exit 1
fi

if [ -d /opt/dotfile ]; then
    echo "Uninstalling old version"
    ${SUDO_CMD} rm -rf /opt/dotfile
fi

# Get files
cd /opt
git clone --depth=1 --branch=master git@github.com:lachlankrautz/dotfile
if cd dotfile; then
    ${SUDO_CMD} rm -rf .git
    ${SUDO_CMD} rm .gitignore
    ${SUDO_CMD} chmod 755 bin/dotfile
else
    exit 1
fi

if [ -f /usr/bin/dotfile ]; then
    ${SUDO_CMD} rm /usr/bin/dotfile
fi
${SUDO_CMD} ln -s /opt/dotfile/bin/dotfile /usr/bin/dotfile

# make sure config file is created for current user
dotfile > /dev/null
