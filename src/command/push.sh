#!/usr/bin/env bash

title_push() {
    doc_title << 'EOF'
                        __
      ____  __  _______/ /
     / __ \/ / / / ___/ __ \
    / /_/ / /_/ (__  ) / / /
   / .___/\__,_/____/_/ /_/
  /_/

EOF
    return 0
}

command_push() {
    local SSH_HOST="${1}"

    title_push

    # Validate request
    if [ -z "${SSH_HOST}" ]; then
        error "Missing host"
        return 1
    fi
    if [ -z "${config_dir}" ]; then
        error "Missing config dir"
        return 1
    fi
    if [ -z "${repo}" ]; then
        error "Missing repo"
        return 1
    fi

    heading "Push ${SSH_HOST}"

    local ZIP_FILE="/tmp/config.tgz"

    # Clear temp
    if [ -f "${ZIP_FILE}" ]; then
        rm "${ZIP_FILE}"
        if [ ! "${?}" -eq 0 ]; then
            error "Unable to clear temp: ${ZIP_FILE}"
            return 1
        fi
    fi

    info "Creating config archive"
    tar -zcvf "${ZIP_FILE}" -C "${config_dir}" "${repo}" > /dev/null
    if [ ! "${?}" -eq 0 ] || [ ! -f "${ZIP_FILE}" ]; then
        error "Unable to create config archive"
        return 1
    fi

    info "Copying to server"
    scp "${ZIP_FILE}" "${SSH_HOST}":/tmp
    if [ ! "${?}" -eq 0 ]; then
        error "Unable to copy to server: scp ${ZIP_FILE} ${SSH_HOST}:/tmp"
        return 1
    fi

    info "Clearing temp"
    rm "${ZIP_FILE}"
    if [ ! "${?}" -eq 0 ]; then
        error "Unable to clear temp: ${ZIP_FILE}"
        return 1
    fi

    info "Running script on ${SSH_HOST}"
    ssh -T "${SSH_HOST}" << EOF
export TERM=xterm
export config_dir="${config_dir}"
export repo="${repo}"
export git_repo="${git_repo}"

if [ ! -f "${ZIP_FILE}" ]; then
    echo "Config archive missing"
    exit 1
fi

tar xvfz -C "${config_dir}"
if [ -f "${ZIP_FILE}" ]; then
    rm "${ZIP_FILE}"
fi

if [ -f ~/.config/dotfile/config.ini ]; then
    rm ~/.config/dotfile/config.ini
fi

bash <(curl -s https://raw.githubusercontent.com/lachlankrautz/dotfile/master/install.sh)

# dotfile sync

EOF
    if [ ! "${?}" -eq 0 ]; then
        error "Failed to push to server"
        return 1
    fi
}
