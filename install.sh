#!/usr/bin/env bash

ensure_link() {
    local SUDO_CMD="${1}"
    local SRC="${2%/}"
    local DEST="${3%/}"
    local NAME="${4}"

    echo "Checking path executable ${NAME}"
    local NEED_LINK=0
    local LINK="$(readlink "${DEST}")"
    if [ ! -z "${LINK}" ] && [ ! "${LINK}" = "${SRC}" ]; then
        NEED_LINK=1
        echo "Existing link points elsewhere, removing"
        ${SUDO_CMD} rm "${DEST}"
        if [ ! "${?}" -eq 0 ]; then
            echo "Unable to remove bad link"
            return 1
        fi
    fi
    if [ ! -f "${DEST}" ]; then
        NEED_LINK=1
    fi
    if [ "${NEED_LINK}" -eq 1 ]; then

        echo "Creating system link"
        if [ "${WINDOWS}" -eq 1 ]; then
            local WIN_SRC="$(cygpath -w "${SRC}")"
            local WIN_DEST="$(cygpath -w "${DEST}")"
            local CMD_C="mklink ${WIN_DEST} ${WIN_SRC}"
            cmd /C "\"${CMD_C}\"" > /dev/null 2>&1
        else
            ${SUDO_CMD} ln -s "${SRC}" "${DEST}"
        fi

        if [ ! "${?}" -eq 0 ]; then
            echo "Unable to create system link"
            return 1
        fi
    fi

    if [ -L "${DEST}" ] && [ "$(readlink "${DEST}")" = "${SRC}" ]; then
        echo "Link confirmed"
    else
        echo "Unable to install link"
        return 1
    fi
}

install_dotfile() {
    local SUDO_CMD="sudo"

    local WINDOWS=0
    if [[ "${OS}" =~ .*indows.* ]]; then
        SUDO_CMD=""
        WINDOWS=1
    elif [ "${EUID}" -eq 0 ]; then
        echo "Do not install as root; user home dir is needed"
        return 1
    fi

    if [ ! -d /opt ]; then
        echo "Missing install dir \"/opt\""
        return 1
    fi

    if [ -d /opt/dotfile ]; then
        echo "Removing old version"
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
    git clone --depth=1 --branch=master https://github.com/lachlankrautz/dotfile /tmp/dotfile
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
        echo "Unable to set executable permissions"
        return 1
    fi

    echo "Moving to /opt/dotfile"
    ${SUDO_CMD} mv /tmp/dotfile /opt
    if [ ! "${?}" -eq 0 ]; then
        echo "Unable to move project to /opt"
        return 1
    fi
    echo

    ensure_link "${SUDO_CMD}" "/opt/dotfile/bin/dotfile" "/usr/bin/dotfile" "dotfile"
    ensure_link "${SUDO_CMD}" "/opt/dotfile/bin/install" "/usr/bin/dotfile-update" "dotfile updater"
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
