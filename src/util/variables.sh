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
#   PREVIEW
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
#   NESTING_FILE
#   NESTED_DIRS

load_global_variables() {
    VERSION="1.6"
    HELP=0
    if ! truth "${PREVIEW}";  then
        PREVIEW=0
    fi
    local UNAME="$(uname)"
    [ "${UNAME}" = "Linux" ] && LINUX=1 || LINUX=0
    [[ "${OS}" =~ .*indows.* ]] && WINDOWS=1 || WINDOWS=0
    UNIX_HOME="~"
    WIN_HOME=""
    if [ ${WINDOWS} -eq 1 ] && [ -n "${HOMEDRIVE}" ] && [ -n "${HOMEPATH}" ]; then
        WIN_HOME=$(echo "${HOMEDRIVE}${HOMEPATH}" | sed 's|\\|/|g')
    fi
    HOME_DIR="$(abspath "~")"
    IS_ROOT=0
    if truth "${LINUX}" && [ "${EUID}" -eq 0 ]; then
        IS_ROOT=1
        HOME_DIR="/root"
        if [ -z "${TRUE_HOME_DIR}" ]; then
            error "Unable to determine home dir"
            exit
        fi
    else
        TRUE_HOME_DIR="${HOME_DIR}"
    fi

    ensure_config

    config_dir="${config_dir%/}"
    if [ ! -z "${TRUE_HOME_DIR}" ]; then
        config_dir="${config_dir/~/${TRUE_HOME_DIR}}"
    fi

    BACKUP_DIR="${config_dir}/backup_home"
    ROOT_BACKUP_DIR="${config_dir}/root_backup_home"
    SYNC_EXCLUDE=(".git" ".gitignore")
    DOTFILES_DIR="${config_dir}/${repo}"
    NESTING_FILE="${config_dir}/${repo}/nesting_list.txt"
    CHECKED=()
    update_filesystem_variables
}

update_filesystem_variables() {
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
    NESTED_DIRS=()
    if [ -f "${NESTING_FILE}" ]; then
        readarray NESTED_DIRS < "${NESTING_FILE}"
        NESTED_DIRS=("${NESTED_DIRS[@]//[$'\t\r\n ']}")
    fi
}

ensure_config() {
    local PATH_CONFIG="${TRUE_HOME_DIR}/.config/dotfile"
    local FILE="${PATH_CONFIG}/config.ini"

    if [ ! -d "${PATH}" ]; then
        if ! mkdir -p "${PATH_CONFIG}"; then
            error "Unable to create config dir: ${PATH_CONFIG}"
            exit 1
        fi
    fi

    if [ ! -f "${FILE}" ]; then
        create_config "${FILE}"
        if [ ! -f "${FILE}" ]; then
            error "Unable to create config file: ${FILE}"
            exit 1
        fi
    fi

    cfg_parser "${FILE}"
    if ! cfg_section_dotfile; then
        error "Failed to load config: ${FILE}"
        exit 1
    fi

    return 0
}

create_config() {
    local FILE="${1}"

    if [ -z "${config_dir}" ]; then
        config_dir="~/config"
    fi
    if [ -z "${repo}" ]; then
        repo="my-config"
    fi
    if [ -z "${git_repo}" ]; then
        git_repo=""
    fi

    cat << EOF >> ${FILE}
[dotfile]
;;; dir for config repo(s) and backups
config_dir=${config_dir}

;;; selected config repo in config_dir
repo=${repo}

;;; config repo address to clone into config_dir (optional)
git_repo=${git_repo}

;;; sync dotfiles to /root
sync_root=0
EOF
}
