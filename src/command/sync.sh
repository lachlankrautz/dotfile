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

command_sync() {
    title_sync
    ensure_filesystem
    ensure_dotfiles
    sync_home "${BACKUP_DIR}"
    if truth "${sync_root}"; then
        sudo_command sync_home "${ROOT_BACKUP_DIR}"
    fi
}

ensure_filesystem() {
    heading "Filesystem"

    ensure_dir "${config_dir}" "config dir"
    ensure_dir "${BACKUP_DIR}" "backup dir"
    truth "${sync_root}" && ensure_dir "${ROOT_BACKUP_DIR}" "root backup dir"
    echo
}

ensure_dotfiles() {
    [ -d "${config_dir}" ] || return 1;

    heading "Config repo"

    if [ ! -d "${DOTFILES_DIR}" ] && [ ! -z "${git_repo}" ]; then
        if ! clone_repo "${git_repo}" "${repo}"; then
            echo
            return 1
        fi
    fi

    local SUCCESS=0
    if ! ensure_dir "${DOTFILES_DIR}" "config repo"; then
        echo
        return 1
    fi
    ensure_dir "${DOTFILES_DIR}/shared" "group" || SUCCESS=1
    if truth "${sync_root}"; then
        ensure_dir "${DOTFILES_DIR}/root" "group" || SUCCESS=1
    fi
    if truth "${WINDOWS}"; then
        ensure_dir "${DOTFILES_DIR}/windows" "group" || SUCCESS=1
    fi
    if truth "${LINUX}"; then
        ensure_dir "${DOTFILES_DIR}/linux" "group" || SUCCESS=1
    fi
    update_filesystem_variables

    ensure_file "${NESTING_FILE}" "nesting file" || SUCCESS=1

    echo
    return "${SUCCESS}"
}

clone_repo() {
    local GIT_REPO="${1}"
    local NAME="${2}"

    # clone into config_dir
    local TEMP_PWD="$(pwd)"
    cd ${config_dir}
    git clone "${git_repo}" "${repo}" && info "Cloned ${git_repo} => ${config_dir}/${repo}"
    local SUCCESS="${?}"
    cd "${TEMP_PWD}"
    return "${SUCCESS}"
}

sync_home() {
    local BACKUP="${1}"

    [ -d "${DOTFILES_DIR}" ] || return 1

    local DEST="${HOME_DIR}"
    if truth "${IS_ROOT}"; then
        DEST="/root"
    fi
    heading "Sync ${DEST}"

    if [ "${#DOTFILE_GROUPS[@]}" = 0 ]; then
        echo "No repo groups available"
        return 1
    fi

    local GROUP_MESSAGE
    if [ "${#DOTFILE_GROUPS[@]}" = 1 ]; then
        GROUP_MESSAGE="${DOTFILE_GROUPS}"
    else
        GROUP_MESSAGE="($(implode "|" "${DOTFILE_GROUPS[@]}"))"
    fi

    info "Dir summary"
    dir_status "           Home" "${DEST}"
    dir_status "    Config repo" "${DOTFILES_DIR}" "/${GROUP_MESSAGE}"
    dir_status "         Backup" "${BACKUP}"

    info "File summary"
    local GROUP
    CHECKED=()
    for GROUP in "${DOTFILE_GROUPS[@]}"; do
        sync_dir "${GROUP}" "${DEST}" "${DOTFILES_DIR}/${GROUP}" "${DEST}" "${BACKUP}"
    done
    if [ "${#CHECKED[@]}" -eq 0 ]; then
        info "No files in config repo, get started with \"dotfile import\""
    fi

    echo
    return 0
}

sync_dir() {
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

            if [ -d "${FILE}" ] && nested_dir "${FILE}"; then
                sync_dir "${GROUP}" "${IGNORE}" "${FILE}" "${DEST}/${FILE_NAME}" "${BACKUP}"

            elif ! in_array "${FILE_REF}" "${CHECKED[@]}"; then
                CHECKED+=("${FILE_REF}")
                smart_link "${GROUP}" "${IGNORE}" "${SRC}" "${DEST}" "${BACKUP}" "${FILE_NAME}"
            fi
        else
            echo "        Ignored: ${FILE_NAME}"
        fi
    done
}
