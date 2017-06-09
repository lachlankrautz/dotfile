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
        echo "Missing file pattern"
        echo
    else
        import_dotfiles_pattern "${FILE}" "${SUB_DIR}"
    fi
    local SUCCESS="${?}"
    return "${SUCCESS}"
}

import_dotfiles_pattern() {
    local PATTERN="${1##*/}"
    local SEARCH_DIR="${1%/*}"
    local GROUP="${2}"
    local MESSAGE="'${PATTERN}'"
    if [ "${PATTERN}" = "${SEARCH_DIR}" ]; then
        SEARCH_DIR=""
    else
        MESSAGE="${SEARCH_DIR} ${MESSAGE}"
    fi

    info "Import ${MESSAGE} into ${repo}"
    local DOTFILES=($(find "${HOME_DIR%/}/${SEARCH_DIR#/}" -maxdepth 1 -mindepth 1 -name "${PATTERN}"))
    if [ "${#DOTFILES[@]}" -eq 0 ]; then
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
    for DOTFILE in "${DOTFILES[@]}"; do
        import_dotfile "${GROUP}" "${DOTFILE}"
    done

    echo
}

import_dotfile() {
    local GROUP="${1}"
    local IMPORT_FILE="${2}"
    local IMPORT_NAME="${2##*/}"
    local FILE_REF="${2//${HOME_DIR}\//}"
    local DOTFILE_PATH="${DOTFILES_DIR}/${GROUP}/${FILE_REF}"
    local IMPORT_DIR="${IMPORT_FILE%/*}"
    local DOTFILE_DIR="${DOTFILE_PATH%/*}"

    if [ ! -e "${IMPORT_FILE}" ]; then
        echo_status "${term_fg_red}" " Import missing" "${FILE_REF}"
        return 1
    fi
    if [ -e "${DOTFILE_PATH}" ]; then
        echo_status "${term_fg_green}" "       Imported" "${FILE_REF}"
        return 1
    fi
    if [ -L "${IMPORT_FILE}" ]; then
        echo_status "${term_fg_red}" " Import is link" "${FILE_REF}"
        return 1
    fi

    if truth "${PREVIEW}"; then
        echo_status "${term_fg_white}" "Import required" "${FILE_REF}"
        return 0
    fi

    if [ ! "${HOME_DIR}" = "${IMPORT_DIR}" ]; then
        ensure_nested_dir "${GROUP}" "${DOTFILE_DIR}" || return 1
    fi

    if mv "${IMPORT_FILE}" "${DOTFILE_PATH}"; then
        echo_status "${term_fg_green}" "       Imported" "${FILE_REF}"
        smart_link "${GROUP}" "${HOME_DIR}" "${DOTFILE_DIR}" "${IMPORT_DIR}" "${BACKUP_DIR}" "${IMPORT_NAME}"
        return 0
    else
        echo_status "${term_fg_red}" "  Import failed" "${FILE_REF}"
        return 1
    fi
}
