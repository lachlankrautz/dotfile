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
    truth ${WRITABLE} && title_sync || title_status

    ensure_filesystem
    ensure_dotfiles
    sync_dir "${DOTFILES_DIR}" "${home_dir}" "${backup_dir}"
    truth ${sync_to_root} && sync_dir "${DOTFILES_DIR}" "/root" "${root_backup_dir}"
}

ensure_filesystem() {
    heading "Filesystem"

    ensure_dir "${dotfiles_home}" "Dotfiles project(s) home"
    ensure_dir "${home_dir}" "Sync dir"
    ensure_dir "${backup_dir}" "Backup dir"
    truth ${sync_to_root} && ensure_dir "${root_backup_dir}" "Root backup dir"
    echo
}

ensure_dotfiles() {
    [ -d "${dotfiles_home}" ] || return 1

    heading "Dotfiles"

    if [ -d "${DOTFILES_DIR}/.git" ]; then
        info "Confirmed dotfiles project ${DOTFILES_DIR}"
        echo
        return 0
    fi
    if [ -z "${dotfiles_git}" ]; then
        warn "Dotfile git is not set"
        echo
        return 1
    fi

    # clone into dotfiles dir
    local TEMP_PWD=$(pwd)
    cd ${dotfiles_home}
    git clone ${dotfiles_git} && info "Cloned ${dotfiles_git} => ${DOTFILES_DIR}"
    local SUCCESS=${?}
    cd ${TEMP_PWD}
    echo
    return ${SUCCESS}
}

sync_dir() {
    local SRC=${1}
    local DEST=${2}
    local BACKUP=${3}
    [ -d "${SRC}" ] || return 1

    heading "Sync ${DEST}"

    info "Dir summary"
    dir_status "       Dotfiles" "${SRC}"
    dir_status "           Home" "${DEST}"
    dir_status "         Backup" "${BACKUP}"

    info "File summary"
    local FILE
    for FILE in $(listdir "${SRC}"); do

        FILE=$(echo ${FILE##*/} | lower)
        if ! in_array "${FILE}" "${SYNC_EXCLUDE[@]}"; then
            smart_link "${SRC}" "${DEST}" "${BACKUP}" "${FILE}"
        else
            echo "        Ignored: ${FILE}"
        fi
    done
    echo
}
