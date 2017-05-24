#!/usr/bin/env bash

load_global_variables() {
    VERSION=1.0
    HELP=0
    WRITABLE=0
    [[ ${OS} =~ .*indows.* ]] && WINDOWS=1 || WINDOWS=0
    UNIX_HOME=~
    WIN_HOME=
    if [ ${WINDOWS} -eq 1 ] && [ -n "${HOMEDRIVE}" ] && [ -n "${HOMEPATH}" ]; then
        WIN_HOME=$(echo "${HOMEDRIVE}${HOMEPATH}" | sed 's|\\|/|g')
    fi

    load_config
}

load_config() {
    ensure_config "default"
    ensure_config "local"

    # trailing slashes not welcome
    dotfiles_home=${dotfiles_home%/}
    home_dir=${home_dir%/}
    backup_dir=${backup_dir%/}
    SYNC_EXCLUDE=(.git .gitignore)

    # get current dotfile dir
    DOTFILES_PROJECT_NAME="${dotfiles_git##*:}"
    DOTFILES_PROJECT_NAME="${DOTFILES_PROJECT_NAME##*/}"
    DOTFILES_PROJECT_NAME="${DOTFILES_PROJECT_NAME%.git}"

    DOTFILES_DIR="${dotfiles_home}/${DOTFILES_PROJECT_NAME}"
    DOTFILES_DIR_SHARED="${DOTFILES_DIR}/shared"
    DOTFILES_DIR_WINDOWS="${DOTFILES_DIR}/windows"
    DOTFILES_DIR_ROOT="${DOTFILES_DIR}/root"
}

ensure_config() {
    local TYPE="${1}"
    local FILE="${PATH_BASE}/config/${TYPE}.ini"

    if [ ! -f "${FILE}" ]; then
        if [ "${TYPE}" = "local" ]; then
            create_local_config "${FILE}"
        else
            error "Missing default config"
            info "Recommend restoring from version control"
            exit
        fi
    fi

    cfg_parser ${FILE}
    cfg_section_general

    local SAFETY="${TYPE}_config_loaded"
    if ! truth "${!SAFETY}"; then
        missing_config "${TYPE}" "${FILE}"
    fi
}

missing_config() {
    local TYPE="${1}"
    local FILE="${2}"

    config_title
    warn "Config incomplete"
    info "Edit your ${TYPE} config file: ${FILE}"
    info "Mark \"${TYPE}_config_loaded=1\" when finished"
    echo
    exit
}

create_local_config() {
    local CONFIG_LOCAL="${1}"

    cat << EOF >> ${CONFIG_LOCAL}
;;; Local config - not in version control

[general]

;;; safety to ensure config has been checked by user
local_config_loaded=0

;;; git repository holding dotfiles
dotfiles_git=

;;; home dir to clone dotfile repo(s) into
;;; absolute path or relative to this project
dotfiles_home=~/

;;; home dir to sync to
home_dir=~/

;;; backup dir for displaced home dotfiles
backup_dir=~/home_bak

;;; also sync dotfiles to /root
; sync_to_root=0

;;; backup dir for displaced root dotfiles
; root_backup_dir=
EOF
}

config_title() {
    doc_title << 'EOF'
                      _____
    _________  ____  / __(_)___ _
   / ___/ __ \/ __ \/ /_/ / __ `/
  / /__/ /_/ / / / / __/ / /_/ /
  \___/\____/_/ /_/_/ /_/\__, /
                        /____/

EOF
}
