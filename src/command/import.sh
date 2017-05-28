#!/usr/bin/env bash

title_import() {
    doc_title << 'EOF'
      _                            __
     (_)___ ___  ____  ____  _____/ /_
    / / __ `__ \/ __ \/ __ \/ ___/ __/
   / / / / / / / /_/ / /_/ / /  / /_
  /_/_/ /_/ /_/ .___/\____/_/   \__/
             /_/

EOF
    return 0
}

command_import() {
    local FILE="${1}"
    local SUB_DIR="${2}"
    if [ -z "${SUB_DIR}" ]; then
        SUB_DIR="shared"
    fi

    title_import

    if [ -z "${FILE}" ]; then
        list_available
    else
        import_dotfiles_pattern "${FILE}" "${SUB_DIR}"
    fi
    local SUCCESS="${?}"
    return "${SUCCESS}"
}

list_available() {
    info "Available imports"

    local HOME_FILES=($(listdir "${home_dir}"))
    HOME_FILES=("${HOME_FILES[@]//${home_dir}\//}")
    local DOTFILES
    local LISTED=()

    local SUB_DIRS
    if truth "${sync_to_root}"; then
        SUB_DIRS=("${GROUP_DIRS_ROOT[@]}")
    else
        SUB_DIRS=("${GROUP_DIRS[@]}")
    fi

    local DIR
    local HOME_FILE
    local FOUND
    for HOME_FILE in "${HOME_FILES[@]}"; do

        FOUND=0
        for DIR in "${SUB_DIRS[@]}"; do
            DOTFILES=($(listdir "${DOTFILES_DIR}/${DIR}"))
            DOTFILES=("${DOTFILES[@]//${DIR}\//}")

            if ! in_array "${HOME_FILE}" "${DOTFILES[@]}"; then
                FOUND=1
                break
            fi
        done

        if  truth "${FOUND}" && ! in_array "${HOME_FILE}" "${LISTED[@]}"; then
            LISTED+=("${HOME_FILE}")
            echo "    ${HOME_FILE}"
        fi
    done

    echo
    return 0
}

import_dotfiles_pattern() {
    local PATTERN="${1}"
    local SUB_DIR="${2}"
    WRITABLE=1

    info "Importing ${PATTERN} into ${repo}"
    local DOTFILES=($(find "${home_dir}" -maxdepth 1 -mindepth 1 -name "${PATTERN}"))
    if [ "${#DOTFILES[@]}" -eq 0 ]; then
        error "No files matching pattern: ${PATTERN}"
        echo
        return 1
    fi
    if [ ! -d "${DOTFILES_DIR}/${SUB_DIR}" ]; then
        error "Dotfile group not found: ${SUB_DIR}"
        echo
        return 1
    fi

    DOTFILES=("${DOTFILES[@]//${home_dir}\//}")
    local DOTFILE
    for DOTFILE in "${DOTFILES[@]}"; do
        import_dotfile "${DOTFILE}" "${SUB_DIR}"
    done

    echo
}

import_dotfile() {
    local FILE="${1}"
    local SUB_DIR="${2}"

    local HOME_PATH="${home_dir}/${FILE##*/}"
    local DOTFILE_PATH="${DOTFILES_DIR}/${SUB_DIR}/${FILE##*/}"

    if [ ! -e "${HOME_PATH}" ]; then
        echo_status "${term_fg_red}" " Import missing" "${HOME_PATH}"
        return 1
    fi
    if [ -e "${DOTFILE_PATH}" ]; then
        echo_status "${term_fg_yellow}" "  Already found" "${HOME_PATH}"
        return 1
    fi
    if [ -L "${HOME_PATH}" ]; then
        echo_status "${term_fg_red}" " Import is link" "${HOME_PATH}"
        return 1
    fi

    if mv "${HOME_PATH}" "${DOTFILE_PATH}"; then
        echo_status "${term_fg_green}" "       Imported" "${HOME_PATH}"
        smart_link "${DOTFILES_DIR}" "${SUB_DIR}" "${home_dir}" "${BACKUP_DIR}" "${FILE}"
        return 0
    else
        echo_status "${term_fg_red}" "  Import failed" "${HOME_PATH}"
        return 1
    fi
}
