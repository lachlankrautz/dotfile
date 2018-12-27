#!/usr/bin/env bash

title_export() {
    doc_title << 'EOF'
EXPORT

EOF
    return 0
}

command_export() {
    local PATTERN="${1##*/}"
    local SEARCH_DIR_PART="${1/${PATTERN}/}"
    local SEARCH_DIR
    SEARCH_DIR="$(abspath "${HOME}/$(relpath "${SEARCH_DIR_PART}" "${HOME}")")"

    title_export

    if [ -z "${PATTERN}" ]; then
        echo "Missing file pattern"
        echo
        return 1
    fi

    cdd "${HOME}"
    export_dotfiles_pattern "${SEARCH_DIR}" "${PATTERN}" "${GROUP}"
    return "${?}"
    echo "exporting ..."

    echo
    return 0
}

export_dotfiles_pattern() {
    local SEARCH_DIR="${1}"
    local PATTERN="${2}"
    local GROUP="${3}"

    info "Export ${term_fg_blue}${SEARCH_DIR}/${PATTERN}${term_reset} into ${term_fg_blue}${DOTFILES_DIR}/${GROUP}${term_reset}"
}