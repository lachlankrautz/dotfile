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

dotfile_command_export() {
    local INPUT="${1%/}"
    local PATTERN="${INPUT##*/}"
    local SEARCH_DIR_PART="${1/${PATTERN}/}"
    local SEARCH_DIR
    SEARCH_DIR="$(abspath "${HOME_DIR}/$(relpath "${SEARCH_DIR_PART}" "${HOME_DIR}")")"

    title_export

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

    if truth "${PREVIEW}"; then
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
    local REPO_DIR
    local REPO_FILE
    local FILE_REF

    if [ ! -e "${EXPORT_FILE}" ]; then
        echo_status "${term_fg_red}" "Missing" "${EXPORT_FILE}"
        return 1
    fi

    if [ ! -L "${EXPORT_FILE}" ]; then
        echo_status "${term_fg_green}" "Restored" "${EXPORT_FILE}"
        return 1
    fi

    if truth "${PREVIEW}"; then
        echo_status "${term_fg_white}" "Export" "${EXPORT_FILE}"
        return 0
    fi

    REPO_FILE="$(readlink "${EXPORT_FILE}")"
    if [ -z "${REPO_FILE}" ]; then
        error "Missing linked file for ${EXPORT_FILE}"
        return 1
    fi
    if [ "$(commonpath "${DOTFILES_DIR}" "${REPO_FILE}")" != "${DOTFILES_DIR}" ]; then
        error "Link must point to file inside ${DOTFILES_DIR}: ${REPO_FILE}"
        echo
        return 1
    fi
    FILE_REF="$(file_ref "${REPO_FILE}")"
    local DOTFILE_GROUP_DIR="${REPO_FILE/\/${FILE_REF}/}"
    REPO_DIR="${REPO_FILE%/*}"

    # echo "export file: ${EXPORT_FILE}"
    # echo "repo_file: ${REPO_FILE}"
    # echo "repo dir: ${REPO_DIR}"
    # echo "dotfile group dir: ${DOTFILE_GROUP_DIR}"
    # return 0


    if ! rm "${EXPORT_FILE}"; then
        error "Failed to remove link ${EXPORT_FILE}"
        return 1
    fi
    if ! mv "${REPO_FILE}" "${EXPORT_FILE}"; then
        error "Failed to restore ${EXPORT_FILE}"
        return 1
    fi
    dotfile_git_add "${REPO_FILE}" || return 1

    if [ "${DOTFILE_GROUP_DIR}" != "${REPO_DIR}" ]; then
        cleanup_nested_dir "${DOTFILE_GROUP_DIR}" "${REPO_DIR}" || return 1
    fi

    echo_status "${term_fg_green}" "Restored" "${EXPORT_FILE}"
}
