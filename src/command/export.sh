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
    SEARCH_DIR="$(abspath "${DOTFILES_DIR}/$(relpath "${SEARCH_DIR_PART}" "${DOTFILES_DIR}")")"

    title_export

    if [ -z "${PATTERN}" ]; then
        echo "Missing file pattern"
        echo
        return 1
    fi

    if [ "$(commonpath "${DOTFILES_DIR}" "${SEARCH_DIR}")" != "${DOTFILES_DIR}" ]; then
        error "Pattern must point to files inside ${DOTFILES_DIR}"
        echo
        return 1
    fi

    info "Export ${term_fg_blue}${SEARCH_DIR}/${PATTERN}${term_reset}"

    local DOTFILE_LIST=($(find "${SEARCH_DIR}" -maxdepth 1 -mindepth 1 -name "${PATTERN}"))
    if [ "${#DOTFILE_LIST[@]}" -eq 0 ]; then
        warn "No files matching pattern: ${PATTERN}"
        echo
        return 1
    fi

    local SUCCESS=0
    local DOTFILE
    for DOTFILE in "${DOTFILE_LIST[@]}"; do
        export_dotfile "${DOTFILE}" || SUCCESS=1
    done
    echo

    return "${SUCCESS}"
}

export_dotfile() {
    local EXPORT_FILE="${1}"
    local FILE_REF

    if [ ! -e "${EXPORT_FILE}" ]; then
        echo_status "${term_fg_red}" "File" "${EXPORT_FILE}"
        return 1
    fi

    FILE_REF="$(file_ref "${EXPORT_FILE}")" || return 1
    local HOME_FILE="${HOME_DIR}/${FILE_REF}"
    if [ ! -L "${HOME_FILE}" ]; then
        echo_status "${term_fg_red}" "Missing" "${FILE_REF}"
        return 1
    fi

    if ! rm "${HOME_FILE}"; then
        error "Failed to remove link ${HOME_FILE}"
        return 1
    fi
    if ! mv "${EXPORT_FILE}" "${HOME_FILE}"; then
        error "Failed to restore ${HOME_FILE}"
        return 1
    fi
    if ! dotfile_git add "${EXPORT_FILE}"; then
        error "Failed to add ${EXPORT_FILE} to git"
        return 1
    fi

    echo_status "${term_fg_green}" "Restored" "${FILE_REF}"
}
