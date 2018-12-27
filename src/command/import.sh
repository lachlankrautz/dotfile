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
    local PATTERN="${1##*/}"
    local SEARCH_DIR_PART="${1/${PATTERN}/}"
    local GROUP="${2-shared}"
    local SEARCH_DIR
    SEARCH_DIR="$(abspath "${HOME}/$(relpath "${SEARCH_DIR_PART}" "${HOME}")")"

    title_import

    if [ -z "${PATTERN}" ]; then
        echo "Missing file pattern"
        echo
        return 1
    fi

    cdd "${HOME}"
    import_dotfiles_pattern "${SEARCH_DIR}" "${PATTERN}" "${GROUP}"
    return "${?}"
}

import_dotfiles_pattern() {
    local SEARCH_DIR="${1}"
    local PATTERN="${2}"
    local GROUP="${3}"

    info "Import ${term_fg_blue}${SEARCH_DIR}/${PATTERN}${term_reset} into ${term_fg_blue}${DOTFILES_DIR}/${GROUP}${term_reset}"

    local DOTFILE_LIST=($(find "${SEARCH_DIR}" -maxdepth 1 -mindepth 1 -name "${PATTERN}"))
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

    if ! mv "${IMPORT_FILE}" "${DOTFILE_PATH}"; then
        echo_status "${term_fg_red}" "  Import failed" "${FILE_REF}"
        return 1
    fi

    echo_status "${term_fg_green}" "       Imported" "${FILE_REF}"
    smart_link "${GROUP}" "${HOME_DIR}" "${DOTFILE_DIR}" "${IMPORT_DIR}" "${BACKUP_DIR}" "${IMPORT_NAME}"
    return "${?}"
}
