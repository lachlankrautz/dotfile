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

    # check_filesystem

    heading "Sync dotfiles"
    sync_dotfiles
    echo

    heading "Sync home"
    sync_home ${DOTFILES_DIR} ${home_dir}
    echo

    truth ${sync_to_root} && {
        heading "Sync root"
        sync_home ${DOTFILES_DIR} /root
        echo
    }
}

check_filesystem() {
    heading "Config"
    echo
}

sync_dotfiles() {
    ensure_dir "dotfiles home" ${dotfiles_home} || return

    if [ -d "${DOTFILES_DIR}/.git" ]; then
        info "Confirmed dotfiles ${DOTFILES_DIR}"
        return 0
    fi

    if [ -z "${dotfiles_git}" ]; then
        warn "Dotfile git is not set"
        return 1
    fi

    # clone into dotfiles dir
    local TEMP_PWD=$(pwd)
    cd ${dotfiles_home}
    git clone ${dotfiles_git} && info "Cloned ${dotfiles_git} => ${DOTFILES_DIR}"
    local SUCCESS=${?}
    cd ${TEMP_PWD}
    return ${SUCCESS}
}

sync_home() {
    # don't attempt to create /root
    local MESSAGE="Missing sync dir ${2}"
    if [ ${2} = /root ]; then
        if [ ! -d /root ]; then
            warn ${MESSAGE}
            return
        fi
    else
        ensure_dir "Sync dir" ${2} || return
    fi

    info "Confirmed sync dir ${2}"
    [ -d ${1} ] || return

    local FILE
    for FILE in $(listdir ${1}); do
        FILE=$(echo ${FILE} | lower)
        if [ $(in_array ${FILE} ${SYNC_EXCLUDE}) ]; then
            echo "in array: ${FILE}"
        else
            echo "not in array: ${FILE}"
        fi
        # smart_link ${1} ${2} ${FILE##*/}
    done
}
