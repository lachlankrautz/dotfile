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
    sync_dir "${DOTFILES_DIR}" "${home_dir}" "${BACKUP_DIR}"
    truth "${sync_to_root}" && sync_dir "${DOTFILES_DIR}" "/root" "${ROOT_BACKUP_DIR}"
}

ensure_filesystem() {
    heading "Filesystem"

    ensure_dir "${home_dir}" "home dir"
    ensure_dir "${config_dir}" "config dir"
    ensure_dir "${BACKUP_DIR}" "backup dir"
    truth "${sync_to_root}" && ensure_dir "${ROOT_BACKUP_DIR}" "Root backup dir"
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
    if truth "${sync_to_root}"; then
        ensure_dir "${DOTFILES_DIR}/root" "group" || SUCCESS=1
    fi
    if truth "${WINDOWS}"; then
        ensure_dir "${DOTFILES_DIR}/windows" "group" || SUCCESS=1
    fi
    if truth "${LINUX}"; then
        ensure_dir "${DOTFILES_DIR}/linux" "group" || SUCCESS=1
    fi
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

sync_dir() {
    local SRC="${1}"
    local DEST="${2}"
    local BACKUP="${3}"

    [ -d "${SRC}" ] || return 1

    heading "Sync ${DEST}"


    # Build ordered sources list
    local SUB_DIRS=()
    if [ "${DEST}" = "/root" ] && [ -d "${SRC}/root" ]; then
        SUB_DIRS+=("root")
    fi
    if truth ${WINDOWS} && [ -d "${SRC}/windows" ]; then
        SUB_DIRS+=("windows")
    fi
    if truth ${LINUX} && [ -d "${SRC}/linux" ]; then
        SUB_DIRS+=("linux")
    fi
    if [ -d "${SRC}/shared" ]; then
        SUB_DIRS+=("shared")
    fi
    if [ "${#SUB_DIRS[@]}" = 0 ]; then
        return 1
    fi

    local GROUPS_MESSAGE
    if [ "${#SUB_DIRS[@]}" = 1 ]; then
        GROUPS_MESSAGE="${SUB_DIRS}"
    else
        GROUPS_MESSAGE="($(implode "|" "${SUB_DIRS[@]}"))"
    fi

    info "Dir summary"
    dir_status "           Home" "${DEST}"
    dir_status "    Config repo" "${SRC}" "/${GROUPS_MESSAGE}"
    dir_status "         Backup" "${BACKUP}"

    info "File summary"
    local FILE
    local FILE_CHECK
    local CHECKED=()
    for SUB_DIR in "${SUB_DIRS[@]}"; do

        for FILE in $(listdir "${SRC}/${SUB_DIR}"); do

            FILE="${FILE##*/}"
            FILE_CHECK=$(echo "${FILE}" | lower)

            if ! in_array "${FILE_CHECK}" "${SYNC_EXCLUDE[@]}"; then

                if ! in_array "${FILE_CHECK}" "${CHECKED[@]}"; then
                    CHECKED+=("${FILE_CHECK}")
                    smart_link "${SRC}" "${SUB_DIR}" "${DEST}" "${BACKUP}" "${FILE}"
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
