#!/usr/bin/env bash

install_dotfile() {
    local SUDO_CMD="sudo"

    if [[ "${OS}" =~ .*indows.* ]]; then
	SUDO_CMD=""
    else
	if [ "${EUID}" -eq 0 ]; then
            echo "Do not install as root; user home dir is needed"
            return 1
	fi
    fi

    if [ ! -d /opt ]; then
	echo "Missing install dir \"/opt\""
	return 1
    fi

    if [ -d /opt/dotfile ]; then
	echo "Uninstalling old version"
	${SUDO_CMD} rm -rf /opt/dotfile
	if [ ! "${?}" -eq 0 ]; then
	    echo "Unable to remove old version"
	    return 1
	fi
	echo
    fi

    if [ ! -d /tmp ]; then
	echo "Missing temp dir"
	return 1
    fi

    if [ -d /tmp/dotfile ]; then
	rm -rf /tmp/dotfile
	if [ ! "${?}" -eq 0 ]; then
	    echo "Unable to clear temp"
	    return 1
	fi
    fi

    echo "Downloading"
    git clone --depth=1 --branch=master git@github.com:lachlankrautz/dotfile /tmp/dotfile
    if [ ! "${?}" -eq 0 ]; then
	echo "Unable to clone project"
	return 1
    fi
    echo

    rm -rf /tmp/dotfile/.git /tmp/dotfile/.gitignore
    if [ ! "${?}" -eq 0 ]; then
	echo "Unable to clean up git files"
	return 1
    fi

    chmod 755 /tmp/dotfile/bin/dotfile
    if [ ! "${?}" -eq 0 ]; then
	echo "Unable to set execuable permissions"
	return 1
    fi

    echo "Moving to /opt/dotfile"
    ${SUDO_CMD} mv /tmp/dotfile /opt
    if [ ! "${?}" -eq 0 ]; then
	echo "Unable to move project to /opt"
	return 1
    fi
    echo

    echo "Checking path executable"
    local NEED_LINK=0
    local LINK=$(readlink /usr/bin/dotfile)
    if [ ! -z "${LINK}" ] && [ ! "${LINK}" = "/opt/dotfile/bin/dotfile" ]; then
	NEED_LINK=1
	echo "Existing link points elsewhere, removing"
	${SUDO_CMD} rm /usr/bin/dotfile
	if [ ! "${?}" -eq 0 ]; then
	    echo "Unable to remove bad link"
	    return 1
	fi
    fi
    if [ ! -f /usr/bin/dotfile ]; then
	NEED_LINK=1
    fi
    if [ "${NEED_LINK}" -eq 1 ]; then
	echo "Creating system link"
	${SUDO_CMD} ln -s /opt/dotfile/bin/dotfile /usr/bin/dotfile
	if [ ! "${?}" -eq 0 ]; then
	    echo "Unable to create system link"
	    return 1
	fi
    fi

    if [ -L /usr/bin/dotfile ] && [ "$(readlink /usr/bin/dotfile)" = "/opt/dotfile/bin/dotfile" ]; then
	echo "Link confirmed"
    else
	echo "Unable to install link"
	return 1
    fi
    echo

    # run to make sure config file is created for current user
    dotfile > /dev/null
    local RESULT="${?}"
    return "${RESULT}"
}

echo "Installing dotfile"
echo

install_dotfile
if [ "${?}" -eq 0 ]; then
    echo "Install completed"
    echo
    exit 0
else
    echo "Install failed"
    echo
    exit 1
fi
