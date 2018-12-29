#!/usr/bin/env bash

title_sync() {
    doc_title << 'EOF'
     _______  ______  _____
    / ___/ / / / __ \/ ___/
   (__  ) /_/ / / / / /__
  /____/\__, /_/ /_/\___/
       /____/

EOF
}

dotfile_command_sync() {
    title_sync
    ensure_filesystem
    sync_home "${BACKUP_DIR}"
    if truth "${sync_root}"; then
        sudo_command sync_home "${ROOT_BACKUP_DIR}"
    fi
}

ensure_filesystem() {
    if truth "${PREVIEW}"; then
        info "Preview"
        echo
    fi

    local HEADING="Dotfiles"
    if [ ! -z "${DOTFILES_REPO}" ]; then
        HEADING+=" ${term_fg_green}${DOTFILES_REPO}${term_reset}"
    else
        HEADING+=" ${term_fg_green}${DOTFILES_DIR}${term_reset}"
    fi
    heading "${HEADING}"

    display_ensure_dir "${DOTFILES_DIR}" "config" || return 1
    display_ensure_dir "${BACKUP_DIR}" "backup" || return 1
    if truth "${sync_root}"; then
        display_ensure_dir "${ROOT_BACKUP_DIR}" "root backup" || return 1
    fi

    if [ ! -d "${DOTFILES_DIR}" ] && [ ! -z "${DOTFILES_DIR}" ]; then
        if ! clone_repo "${DOTFILES_REPO}" "${DOTFILES_DIR}"; then
            error "Failed to clone ${DOTFILES_REPO}"
            echo
            return 1
        fi
    fi
    [ -d "${DOTFILES_DIR}" ] || return 1;

    local SUCCESS=0
    local DOTFILE_GROUP
    for DOTFILE_GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        display_ensure_dir "${DOTFILES_DIR}/${DOTFILE_GROUP}" "${DOTFILE_GROUP} group" || SUCCESS=1
    done
    echo

    return "${SUCCESS}"
}

clone_repo() {
    local GIT_REPO="${1}"
    local NAME="${2}"

    if ! git clone "${GIT_REPO}" "${NAME}"; then
        error "Failed to clone ${GIT_REPO}"
        return 1
    fi

    info "Cloned ${GIT_REPO} => ${NAME}"
    return 0
}

sync_home() {
    local BACKUP="${1}"

    [ -d "${DOTFILES_DIR}" ] || return 1

    local DEST="${HOME_DIR}"
    if truth "${IS_ROOT}"; then
        DEST="/root"
    fi
    heading "Sync ${DEST}"

    if [ "${#DOTFILE_GROUP_LIST[@]}" = 0 ]; then
        echo "No repo groups available"
        return 1
    fi

    local GROUP
    CHECKED=()
    for GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        sync_dir_recursive "${GROUP}" "${DEST}" "${DOTFILES_DIR}/${GROUP}" "${DEST}" "${BACKUP}"
    done
    if [ "${#CHECKED[@]}" -eq 0 ]; then
        info "No files in config repo, get started with \"dotfile import\""
    fi

    echo
    return 0
}

sync_dir_recursive() {
    local GROUP="${1%/}"
    local IGNORE="${2%/}"
    local SRC="${3%/}"
    local DEST="${4%/}"
    local BACKUP="${5%/}"

    local FILE
    local FILE_REF
    local FILE_NAME
    for FILE in $(listdir "${SRC}"); do
        FILE_REF="$(echo "${FILE/${DOTFILES_DIR}\/${GROUP}\//}" | lower)"
        FILE_NAME="${FILE##*/}"

        if ! in_array "${FILE_NAME}" "${SYNC_EXCLUDE[@]}"; then
            if is_nested_dir "${FILE}"; then
                sync_dir_recursive "${GROUP}" "${IGNORE}" "${FILE}" "${DEST}/${FILE_NAME}" "${BACKUP}"
            elif ! in_array "${FILE_REF}" "${CHECKED[@]}"; then
                CHECKED+=("${FILE_REF}")
                smart_link "${GROUP}" "${IGNORE}" "${SRC}" "${DEST}" "${BACKUP}" "${FILE_NAME}"
            fi
        fi
    done
}
