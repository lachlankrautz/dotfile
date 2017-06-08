#!/usr/bin/env bash

# Establish global variables from config files and system
#
# From lib:
#   TIMESTAMP
#   term_fg_red
#   term_fg_yellow
#   term_fg_green
#   term_fg_white
#   term_fg_blue
#   term_bold
#   term_reset
#
# From config:
#   config_dir
#   repo
#   git_repo
#   sync_root
#
# From system:
#   PATH_BASE
#   VERSION
#   HELP
#   WRITABLE
#   UNIX_HOME
#   WIN_HOME
#   OS
#   WINDOWS
#   LINUX
#   HOME_DIR
#   IS_ROOT
#   HOMEDRIVE
#   HOMEPATH
#   BACKUP_DIR
#   ROOT_BACKUP_DIR
#   SYNC_EXCLUDE
#   DOTFILES_DIR
#   DOTFILE_GROUPS
#   TRUE_HOME_DIR

load_global_variables() {
    VERSION="1.0"
    HELP=0
    if ! truth "${WRITABLE}";  then
        WRITABLE=0
    fi
    local UNAME="$(uname)"
    [ "${UNAME}" = "Linux" ] && LINUX=1 || LINUX=0
    [[ "${OS}" =~ .*indows.* ]] && WINDOWS=1 || WINDOWS=0
    UNIX_HOME=~
    WIN_HOME=
    if [ ${WINDOWS} -eq 1 ] && [ -n "${HOMEDRIVE}" ] && [ -n "${HOMEPATH}" ]; then
        WIN_HOME=$(echo "${HOMEDRIVE}${HOMEPATH}" | sed 's|\\|/|g')
    fi
    HOME_DIR="$(abspath "~")"
    IS_ROOT=0
    if truth "${LINUX}" && [ "${EUID}" -eq 0 ]; then
       IS_ROOT=1
       HOME_DIR="/root"
    fi

    local BAD_CONFIGS=()
    ensure_config "default" "Default config - in version control"
    ensure_config "local" "Local config - not in version control"

    # trailing slashes not welcome
    config_dir="${config_dir%/}"
    if [ ! -z "${TRUE_HOME_DIR}" ]; then
        config_dir="${config_dir/~/${TRUE_HOME_DIR}}"
    fi

    BACKUP_DIR="${config_dir}/backup_home"
    ROOT_BACKUP_DIR="${config_dir}/root_backup_home"
    SYNC_EXCLUDE=(".git" ".gitignore")
    DOTFILES_DIR="${config_dir}/${repo}"
    CHECKED=()
    update_group_dirs
}

update_group_dirs() {
    DOTFILE_GROUPS=()
    if truth "${IS_ROOT}" && [ -d "${DOTFILES_DIR}/root" ]; then
        DOTFILE_GROUPS+=("root")
    fi
    if truth "${WINDOWS}" && [ -d "${DOTFILES_DIR}/windows" ]; then
        DOTFILE_GROUPS+=("windows")
    fi
    if truth "${LINUX}" && [ -d "${DOTFILES_DIR}/linux" ]; then
        DOTFILE_GROUPS+=("linux")
    fi
    if [ -d "${DOTFILES_DIR}/shared" ]; then
        DOTFILE_GROUPS+=("shared")
    fi
}

ensure_config() {
    local TYPE="${1}"
    local TITLE="${2}"
    local FILE="${PATH_BASE}/config/${TYPE}.ini"

    if [ ! -f "${FILE}" ]; then
        create_config "${TYPE}" "${FILE}" "${TITLE}"
    fi

    cfg_parser "${FILE}"
    cfg_section_general

    return 0
}

create_config() {
    local TYPE="${1}"
    local FILE="${2}"
    local TITLE="${3}"

    cat << EOF >> ${FILE}
;;; ${TITLE}

[general]

;;; dir for config repo(s) and backups
config_dir=~/config

;;; selected config repo in config_dir
repo=my-config

;;; config repo address to clone into config_dir (optional)
git_repo=

;;; also sync dotfiles to /root
sync_root=0
EOF
}
