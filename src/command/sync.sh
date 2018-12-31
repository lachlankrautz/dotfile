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
    # title_sync
    # display_ensure_filesystem
    sync_config_to_home "${BACKUP_DIR}"
    # truth "${sync_root}" && sudo_command sync_config_to_home "${ROOT_BACKUP_DIR}"
}

display_ensure_filesystem() {
    if truth "${PREVIEW}"; then
        info "Preview"
        echo
    fi

    local HEADING
    [ -n "${DOTFILES_REPO}" ] && HEADING="${DOTFILES_REPO}" || HEADING="${DOTFILES_DIR}"
    heading "Dotfiles ${term_fg_green}${HEADING}${term_reset}"

    display_ensure_dir "${DOTFILES_DIR}" "config" || return 1
    display_ensure_dir "${BACKUP_DIR}" "backup" || return 1
    truth "${sync_root}" && {
        display_ensure_dir "${ROOT_BACKUP_DIR}" "root backup" || return 1;
    }

    ensure_dotfiles_dir || return 1

    local SUCCESS=0
    local DOTFILE_GROUP
    for DOTFILE_GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        display_ensure_dir "${DOTFILES_DIR}/${DOTFILE_GROUP}" "${DOTFILE_GROUP} group" || SUCCESS=1
    done
    echo

    return "${SUCCESS}"
}

ensure_dotfiles_dir() {
    [ -d "${DOTFILES_DIR}" ] && return 0

    if [ -z "${DOTFILES_REPO}" ]; then
        error "Missing dotfiles repo config"
        return 1
    fi

    if ! clone_repo "${DOTFILES_REPO}" "${DOTFILES_DIR}"; then
        error "Failed to clone ${DOTFILES_REPO}"
        echo
        return 1
    fi

    [ -d "${DOTFILES_DIR}" ]
}

sync_config_to_home() {
    local BACKUP="${1%/}"
    local DEST_DIR
    truth "${IS_ROOT}" && DEST_DIR="/root" || DEST_DIR="${HOME_DIR}"

    heading "Sync ${DEST_DIR}"

    if [ "${#DOTFILE_GROUP_LIST[@]}" = 0 ]; then
        echo "No repo groups available"
        return 1
    fi

    # Spin through groups syncing files
    # Skip files handled by a previous group
    local GROUP

    # WARNING: Global mutable variable
    HANDLED_FILE_LIST=()

    for GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        # sync_dir_recursive "${GROUP}" "${DEST_DIR}" "${DOTFILES_DIR}/${GROUP}" "${DEST_DIR}" "${BACKUP}"
        sync_config_group_to_dir "${GROUP}" "${DEST_DIR}" "${BACKUP_DIR}"
    done

    if [ "${#HANDLED_FILE_LIST[@]}" -eq 0 ]; then
        info "No files in config repo, get started with \"dotfile import\""
    fi
    echo

    return 0
}

sync_config_group_to_dir() {
    local GROUP="${1}"
    local SRC_DIR="${DOTFILES_DIR}/${GROUP}"
    local DEST_DIR="${2%/}"
    local BACKUP_DIR="${3%/}"
    local FILE
    local FILE_REF
    local STATUS=0

    local FIND_ARGS=(
        "${SRC_DIR}"
        -mindepth 1
        -not -name ".git"
        -not -name ".gitignore"
        -not -name ".DS_Store"
        -not -name ".thumbs.db"
        -not -name "${DOTFILE_MARKER}"
        -print0
    )
    while read -r -d $'\0' FILE; do
        # Skip dir containing a `${DOTFILE_MARKER}`
        if [ -d "${FILE}" ] && [ -f "${FILE}/${DOTFILE_MARKER}" ]; then
            continue
        fi

        # Skip file unless dir contains a `${DOTFILE_MARKER}`
        if [ -f "${FILE}" ] && [ ! -f "${FILE%/*}/${DOTFILE_MARKER}" ]; then
            continue
        fi

        FILE_REF="${FILE/${SRC_DIR}\//}"
        smart_link "${GROUP}" "${SRC_DIR}" "${DEST_DIR}" "${BACKUP_DIR}" "${FILE_REF}"
    done < <(find "${FIND_ARGS[@]}")

    return "${STATUS}"
}

sync_dir_recursive() {
    local GROUP="${1%/}"
    # TODO wrong name for variable ignore?
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
            elif ! in_array "${FILE_REF}" "${HANDLED_FILE_LIST[@]}"; then
                HANDLED_FILE_LIST+=("${FILE_REF}")
                smart_link "${GROUP}" "${IGNORE}" "${SRC}" "${DEST}" "${BACKUP}" "${FILE_NAME}"
            fi
        fi
    done
}
