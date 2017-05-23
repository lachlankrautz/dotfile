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
    title_import

    local FILE="${1}"
    if [ -z "${FILE}" ]; then
        list_available
    else
        import_dotfiles_pattern "${FILE}"
    fi
    local SUCCESS=${?}
    return ${SUCCESS}
}

list_available() {
    info "Available imports"

    local DOTFILES=$(listdir "${DOTFILES_DIR_SHARED}")
    DOTFILES="${DOTFILES[@]//${DOTFILES_DIR_SHARED}\//}"

    local HOME_FILES=$(listdir "${home_dir}")
    HOME_FILES="${HOME_FILES[@]//${home_dir}\//}"

    local HOME_FILE
    for HOME_FILE in ${HOME_FILES}; do
        if ! in_array "${HOME_FILE}" ${DOTFILES}; then
            echo "    ${HOME_FILE}"
        fi
    done
    echo
    return 0
}

import_dotfiles_pattern() {
    local PATTERN="${1}"
    WRITABLE=1

    info "Importing ${PATTERN}"
    local DOTFILES=$(find "${home_dir}" -maxdepth 1 -mindepth 1 -name "${PATTERN}")
    DOTFILES="${DOTFILES[@]//${home_dir}\//}"
    local DOTFILE
    for DOTFILE in ${DOTFILES}; do
        import_dotfile "${DOTFILE}"
    done

    echo
}

import_dotfile() {
    local FILE="${1}"
    local HOME_PATH="${home_dir}/${FILE##*/}"
    local DOTFILE_PATH="${DOTFILES_DIR_SHARED}/${FILE##*/}"

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
        smart_link "${DOTFILES_DIR_SHARED}" "${home_dir}" "${backup_dir}" "${FILE}"
        return 0
    else
        echo_status "${term_fg_red}" "  Import failed" "${HOME_PATH}"
        return 1
    fi
}
