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

    if truth "${PREVIEW}"; then
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

import_dotfile() {
    local GROUP="${1}"
    local IMPORT_FILE="${2}"
    local IMPORT_NAME="${2##*/}"
    local FILE_REF="${2//${HOME_DIR}\//}"
    local DOTFILE_PATH="${DOTFILES_DIR}/${GROUP}/${FILE_REF}"
    local IMPORT_DIR="${IMPORT_FILE%/*}"
    local DOTFILE_DIR="${DOTFILE_PATH%/*}"

    if [ ! -e "${IMPORT_FILE}" ]; then
        echo_status "${term_fg_red}" "Missing" "${FILE_REF}"
        return 1
    fi
    if [ -e "${DOTFILE_PATH}" ]; then
        echo_status "${term_fg_green}" "Imported" "${FILE_REF}"
        return 1
    fi
    if [ -L "${IMPORT_FILE}" ]; then
        echo_status "${term_fg_red}" "Link" "${FILE_REF}"
        return 1
    fi

    if truth "${PREVIEW}"; then
        echo_status "${term_fg_white}" "Import" "${FILE_REF}"
        return 0
    fi

    if [ "${HOME_DIR}" != "${IMPORT_DIR}" ]; then
        ensure_nested_dir "${GROUP}" "${DOTFILE_DIR}" || return 1
    fi

    if ! mv "${IMPORT_FILE}" "${DOTFILE_PATH}"; then
        echo_status "${term_fg_red}" "Failed" "${FILE_REF}"
        return 1
    fi

    if ! smart_link "${GROUP}" "${HOME_DIR}" "${DOTFILE_DIR}" "${IMPORT_DIR}" \
            "${BACKUP_DIR}" "${IMPORT_NAME}" > /dev/null; then
        return 1
    fi
    echo_status "${term_fg_green}" "Imported" "${FILE_REF}"

    dotfile_git_add "${DOTFILE_PATH}"
}
