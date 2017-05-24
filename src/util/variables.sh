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
#   local_config_loaded
#   local_config_loaded
#   config_dir
#   repo
#   git_repo
#   home_dir
#   sync_to_root
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
#   HOMEDRIVE
#   HOMEPATH
#   BACKUP_DIR
#   ROOT_BACKUP_DIR
#   SYNC_EXCLUDE
#   DOTFILES_DIR

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

    local BAD_CONFIGS=()
    ensure_config "default" "Default config - in version control" || BAD_CONFIGS+=("default")
    ensure_config "local" "Local config - not in version control" || BAD_CONFIGS+=("local")

    if [ ! "${#BAD_CONFIGS[@]}" -eq 0 ]; then
        missing_config "${BAD_CONFIGS[@]}"
    fi

    # trailing slashes not welcome
    config_dir="${config_dir%/}"
    home_dir="${home_dir%/}"

    BACKUP_DIR="${config_dir}/backup_home"
    ROOT_BACKUP_DIR="${config_dir}/root_backup_home"
    SYNC_EXCLUDE=(.git .gitignore)
    DOTFILES_DIR="${config_dir}/${repo}"
}

ensure_config() {
    local TYPE="${1}"
    local TITLE="${2}"
    local FILE="${PATH_BASE}/config/${TYPE}.ini"

    if [ ! -f "${FILE}" ]; then
        create_config "${TYPE}" "${FILE}" "${TITLE}"
    fi

    cfg_parser ${FILE}
    cfg_section_general

    local SAFETY="${TYPE}_config_loaded"
    if ! truth "${!SAFETY}"; then
        return 1
    fi
    return 0
}

missing_config() {
    local TYPES=("${@}")

    config_title

    local TYPE
    local FILE
    for TYPE in "${TYPES[@]}"; do
        FILE="${PATH_BASE}/config/${TYPE}.ini"

        warn "Config incomplete - ${TYPE}"
        info "Edit your ${TYPE} config file: ${FILE}"
        info "Mark \"${TYPE}_config_loaded=1\" when finished"
        echo
    done
    exit
}

create_config() {
    local TYPE="${1}"
    local FILE="${2}"
    local TITLE="${3}"

    cat << EOF >> ${FILE}
;;; ${TITLE}

[general]

;;; safety to ensure config has been confirmed
${TYPE}_config_loaded=0

;;; home dir to sync to
home_dir=~/

;;; dir for config repo(s) and backups
config_dir=~/config

;;; selected config repo in config_dir
repo=my-config

;;; config repo address to clone into config_dir (optional)
git_repo=

;;; also sync dotfiles to /root
sync_to_root=0
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
