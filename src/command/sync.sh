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

title_status() {
    doc_title << 'EOF'
           __        __
     _____/ /_____ _/ /___  _______
    / ___/ __/ __ `/ __/ / / / ___/
   (__  ) /_/ /_/ / /_/ /_/ (__  )
  /____/\__/\__,_/\__/\__,_/____/

EOF
}

command_sync() {
    truth "${WRITABLE}" && title_sync || title_status

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
    update_group_dirs

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

    local HEADING="Status"
    if truth "${WRITABLE}"; then
        HEADING="Sync"
    fi
    local DEST="${HOME_DIR}"
    if truth "${IS_ROOT}"; then
        DEST="/root"
    fi

    heading "${HEADING} ${DEST}"

    if [ "${#GROUP_DIRS[@]}" = 0 ]; then
        echo "No repo groups available"
        return 1
    fi

    local GROUPS_MESSAGE
    if [ "${#GROUP_DIRS[@]}" = 1 ]; then
        GROUPS_MESSAGE="${GROUP_DIRS}"
    else
        GROUPS_MESSAGE="($(implode "|" "${GROUP_DIRS[@]}"))"
    fi

    info "Dir summary"
    dir_status "           Home" "${DEST}"
    dir_status "    Config repo" "${DOTFILES_DIR}" "/${GROUPS_MESSAGE}"
    dir_status "         Backup" "${BACKUP}"

    info "File summary"
    local GROUP_DIR
    local FILE
    local FILE_CHECK
    local CHECKED=()
    for GROUP_DIR in "${GROUP_DIRS[@]}"; do

        for FILE in $(listdir "${DOTFILES_DIR}/${GROUP_DIR}"); do

            FILE="${FILE##*/}"
            FILE_CHECK=$(echo "${FILE}" | lower)

            if ! in_array "${FILE_CHECK}" "${SYNC_EXCLUDE[@]}"; then

                if ! in_array "${FILE_CHECK}" "${CHECKED[@]}"; then
                    CHECKED+=("${FILE_CHECK}")
                    smart_link "${DOTFILES_DIR}" "${GROUP_DIR}" "${DEST}" "${BACKUP}" "${FILE}"
                fi
            else
                echo "        Ignored: ${FILE}"
            fi
        done
    done
    if [ "${#CHECKED[@]}" -eq 0 ]; then
        info "No files in config repo, get started with \"dotfile import\""
    fi

    echo
    return 0
}
