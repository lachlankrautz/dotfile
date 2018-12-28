#!/usr/bin/env bash

title_export() {
    doc_title << 'EOF'
                                __
    ___  _  ______  ____  _____/ /_
   / _ \| |/_/ __ \/ __ \/ ___/ __/
  /  __/>  </ /_/ / /_/ / /  / /_
  \___/_/|_/ .___/\____/_/   \__/
          /_/

EOF
    return 0
}

command_export() {
    local PATTERN="${1##*/}"
    local SEARCH_DIR_PART="${1/${PATTERN}/}"
    local SEARCH_DIR
    SEARCH_DIR="$(abspath "${HOME_DIR}/$(relpath "${SEARCH_DIR_PART}" "${HOME_DIR}")")"

    title_export

    if [ -z "${PATTERN}" ]; then
        echo "Missing file pattern"
        echo
        return 1
    fi

    info "Export ${term_fg_blue}${SEARCH_DIR}/${PATTERN}${term_reset} into ${term_fg_blue}${DOTFILES_DIR}/${GROUP}${term_reset}"

    local DOTFILE_LIST=($(find "${SEARCH_DIR}" -maxdepth 1 -mindepth 1 -name "${PATTERN}"))
    if [ "${#DOTFILE_LIST[@]}" -eq 0 ]; then
        warn "No files matching pattern: ${PATTERN}"
        echo
        return 1
    fi

    local DOTFILE
    for DOTFILE in "${DOTFILE_LIST[@]}"; do
        import_dotfile "${GROUP}" "${DOTFILE}"
    done

    echo
}

export_dotfile() {
    :
}
