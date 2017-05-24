#!/usr/bin/env bash

load_variables() {
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
    local CONFIG_DEFAULT=${PATH_BASE}/config/default.ini
    local CONFIG_LOCAL=${PATH_BASE}/config/local.ini
    [ -f "${CONFIG_DEFAULT}" ] || die "Missing config file - ${CONFIG_DEFAULT}"
    [ -f "${CONFIG_LOCAL}" ] || cat << EOF >> ${CONFIG_LOCAL}
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

    cfg_parser ${CONFIG_DEFAULT}
    cfg_section_general
    truth ${default_config_loaded} || die "Invalid config - ${CONFIG_DEFAULT}"

    cfg_parser ${CONFIG_LOCAL}
    cfg_section_general
    truth ${local_config_loaded} || die "Invalid config - ${CONFIG_LOCAL}"

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

load_variables
