#!/usr/bin/env bash

title_scp() {
    doc_title << 'EOF'
     ______________
    / ___/ ___/ __ \
   (__  ) /__/ /_/ /
  /____/\___/ .___/
           /_/

EOF
    return 0
}

dotfile_command_scp() {
    local SSH_HOST="${1}"

    warn "WIP, not ready yet"
    return 1

    # Validate request
    if [ -z "${SSH_HOST}" ]; then
        error "Missing host"
        return 1
    fi
    if [ -z "${DOTFILES_DIR}" ]; then
        error "Missing config dir"
        return 1
    fi

    title_ssh

    local DOTFILES_CONTAINING_DIR
    DOTFILES_CONTAINING_DIR="$(dirname "${DOTFILES_DIR}")"
    if [ ! -d "${DOTFILES_CONTAINING_DIR}" ]; then
        mkdir -p "${DOTFILES_CONTAINING_DIR}" || {
            error "Unable to create dir: ${DOTFILES_CONTAINING_DIR}"
            return 1
        }
    fi
    if [ -z "${DOTFILES_REPO}" ]; then
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
    tar -zcvf "${ZIP_FILE}" -C "${DOTFILES_CONTAINING_DIR}" "${DOTFILES_DIR}" > /dev/null
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

    local TILDE="~"
    local TMP_CONFIG_DIR="${DOTFILES_DIR/${TRUE_HOME_DIR}/${TILDE}}"

    info "Running script on ${SSH_HOST}"
    # shellcheck disable=SC2087
    ssh -T "${SSH_HOST}" << EOF
export TERM=xterm
export config_dir="${TMP_CONFIG_DIR}"
export config_repo="${DOTFILES_REPO}"

if [ ! -f "${ZIP_FILE}" ]; then
    echo "Config archive missing"
    exit 1
fi

if [ ! -d "${DOTFILES_CONTAINING_DIR}" ]; then
    mkdir -p "${DOTFILES_CONTAINING_DIR}"
fi
if [ -d "${TMP_CONFIG_DIR}" ]; then
    echo "Clearing old config repo"
    rm -rf "${TMP_CONFIG_DIR}"
fi

tar xvfz "${ZIP_FILE}" -C "${DOTFILES_CONTAINING_DIR}" > /dev/null
if [ -f "${ZIP_FILE}" ]; then
    rm "${ZIP_FILE}"
fi

if [ -f ~/.config/dotfile/config.ini ]; then
    rm ~/.config/dotfile/config.ini
fi

bash <(curl -s https://raw.githubusercontent.com/lachlankrautz/dotfile/master/bin/install)

dotfile sync

EOF
    if [ ! "${?}" -eq 0 ]; then
        error "Failed to push to server"
        return 1
    fi
}
