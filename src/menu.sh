#!/usr/bin/env bash
# shellcheck disable=SC2154

# Empty call
dotfile_() {
    usage
}

# Bad call
dotfile_call_() {
    usage
    return 1
}

dotfile_option_v() {
    dotfile_option_verbose "${@}"
}
dotfile_option_verbose() {
    verbose 1
    dispatch dotfile "$@"
}

dotfile_option_version() {
    echo "Version ${term_fg_yellow}2.0.0${term_reset}"
}

dotfile_option_h() {
    dotfile_option_help "${@}"
}
dotfile_option_help() {
    export HELP=1
    dispatch dotfile "${@}"
}

dotfile_option_p() {
    dotfile_option_preview "${@}"
}
dotfile_option_preview() {
    export PREVIEW=1
    dispatch dotfile "$@"
}

dotfile_command_docker() {
    title_docker
}

dotfile_command_export() {
    local PATTERN="${1##*/}"
    local SEARCH_DIR_PART="${1/${PATTERN}/}"
    local SEARCH_DIR
    SEARCH_DIR="$(abspath "${HOME_DIR}/$(relpath "${SEARCH_DIR_PART}" "${HOME_DIR}")")"
    local INPUT_FILES=("${@}")

    title_export
    echo "pattern: ${PATTERN}"
    echo "dir part: ${SEARCH_DIR_PART}"
    echo
    for I in "${INPUT_FILES[@]}"; do
        echo "${I}"
        echo "link $(readlink "${I}")"
        echo
    done
    return 1;

    if [ -z "${PATTERN}" ]; then
        echo "Missing file pattern"
        echo
        return 1
    fi

    if [ "$(commonpath "${HOME_DIR}" "${SEARCH_DIR}")" != "${HOME_DIR}" ]; then
        error "Pattern must point to files inside ${HOME_DIR}"
        echo
        return 1
    fi

    if [ "${PREVIEW}" -eq 1 ]; then
        info "Preview"
        echo
    fi

    heading "Export ${term_fg_blue}${SEARCH_DIR}/${PATTERN}${term_reset}"

    local DOTFILE_LIST=()
    while IFS= read -r -d $'\0'; do
        DOTFILE_LIST+=("${REPLY}")
    done < <(listdir "${SEARCH_DIR}" -name "${PATTERN}" -print0)

    if [ "${#DOTFILE_LIST[@]}" -eq 0 ]; then
        warn "No files matching pattern: ${PATTERN}"
        echo
        return 1
    fi

    local STATUS=0
    local DOTFILE
    for DOTFILE in "${DOTFILE_LIST[@]}"; do
        export_dotfile "${DOTFILE}" || STATUS=1
    done
    echo

    return "${STATUS}"
}

dotfile_command_import() {
    local INPUT="${1%/}"
    local PATTERN="${INPUT##*/}"
    local SEARCH_DIR_PART="${INPUT/${PATTERN}/}"
    local GROUP="${2-shared}"
    local SEARCH_DIR
    SEARCH_DIR="$(abspath "${HOME_DIR}/$(relpath "${SEARCH_DIR_PART}" "${HOME_DIR}")")"

    title_import

    if [ -z "${PATTERN}" ]; then
        error "Missing file pattern"
        echo
        return 1
    fi

    if [ "$(commonpath "${HOME_DIR}" "${SEARCH_DIR}")" != "${HOME_DIR}" ]; then
        error "Pattern must point to files inside ${HOME_DIR}"
        echo
        return 1
    fi

    if [ "${PREVIEW}" -eq 1 ]; then
        info "Preview"
        echo
    fi

    heading "Import ${term_fg_blue}${SEARCH_DIR}/${PATTERN}${term_reset} into ${term_fg_blue}${DOTFILES_DIR}/${GROUP}${term_reset}"

    local DOTFILE_LIST=()
    while IFS= read -r -d $'\0'; do
        DOTFILE_LIST+=("${REPLY}")
    done < <(listdir "${SEARCH_DIR}" -name "${PATTERN}" -print0)

    if [ "${#DOTFILE_LIST[@]}" -eq 0 ]; then
        warn "No files matching pattern: ${PATTERN}"
        echo
        return 1
    fi
    if [ ! -d "${DOTFILES_DIR}/${GROUP}" ]; then
        error "Dotfile group not found: ${GROUP}"
        echo
        return 1
    fi

    local DOTFILE
    for DOTFILE in "${DOTFILE_LIST[@]}"; do
        import_dotfile "${GROUP}" "${DOTFILE}"
    done

    echo
}

dotfile_command_install() {
    title_install

    create_link "${PATH_BASE}/bin/dotfile" /usr/local/bin/dotfile 1 || return 1
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

dotfile_command_sync() {
    title_sync
    display_ensure_filesystem
    sync_config_to_home "${BACKUP_DIR}"
    [ "${sync_root}" -eq 1 ] && run_with_sudo sync_config_to_home "${ROOT_BACKUP_DIR}"
}

dotfile_command_update() {
    title_update

    if ! dotfile_git diff-index --quiet HEAD --; then
        info "Local config changes detected"
        echo

        dotfile_git status
        echo

        question -p "Stage and commit changes?" -d "yes" || return 1
        dotfile_git commit -p || return 1
    fi

    heading "Updating ${DOTFILES_REPO}"
    echo

    info "git pull --rebase"
    dotfile_git pull --rebase
    echo

    info "git push"
    dotfile_git push
    echo

    info "git status"
    dotfile_git status
    echo
}

dotfile_command_test() {
    local CURRENT=/c/Users/lach/AppData/Roaming
    local TARGET=/c/Users

    while [ "${CURRENT}" != "${TARGET}" ]; do
        echo "${CURRENT}"
        CURRENT="$(dirname "${CURRENT}")"
    done
}
