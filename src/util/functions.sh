#!/usr/bin/env bash

usage() {
    main_title
    cat << EOF
${term_fg_yellow}Usage:${term_reset}
  dotfile [options] <command> <args>

${term_fg_yellow}Options:${term_reset}
  ${term_fg_green}-h, --help${term_reset}               Display usage
  ${term_fg_green}-v, --version${term_reset}            Display version
  ${term_fg_green}-p, --preview${term_reset}            Preview changes

${term_fg_yellow}Commands:${term_reset}
  ${term_fg_green}sync${term_reset}                     Sync repo groups to home
  ${term_fg_green}import${term_reset} <pattern> <group> Import home to repo group (default "shared")
  ${term_fg_green}push${term_reset}   <user@host>       Push config to remote host and sync
  ${term_fg_green}clean${term_reset}                    Remove broken repo links

EOF
}

sudo_command() {
    local SUDO_COMMAND="${1}"; shift;
    sudo -s << EOF
PATH_BASE="${PATH_BASE}"
TRUE_HOME_DIR="$(abspath ${HOME_DIR})"
PREVIEW="${PREVIEW}"
source "${PATH_BASE}/src/util/init.sh"
${SUDO_COMMAND} "${@}"
EOF
}

ensure_not_root() {
    if truth "${IS_ROOT}"; then
        main_title
        error "Must not run as root"
        echo
        exit 1
    fi
}

ensure_dir() {
    local DIR="${1}"
    local NAME="${2}"
    local MESSAGE="${NAME} ${DIR}"
    if [ -z "${DIR}" ]; then
        warn "${NAME} path not set"
        return 1
    fi
    if [ -d "${DIR}" ]; then
        info "Confirmed ${MESSAGE}"
        return 0
    fi
    mkdir -p "${DIR}"
    local SUCCESS="${?}"
    if [ "${SUCCESS}" -eq 0 ]; then
        info "Created ${MESSAGE}"
    else
        warn "Failed to create ${MESSAGE}"
    fi
    return "${SUCCESS}"
}

ensure_file() {
    local FILE="${1}"
    local NAME="${2}"
    local MESSAGE="${NAME} ${FILE}"
    if [ -z "${FILE}" ]; then
        warn "${NAME} path not set"
        return 1
    fi
    if [ -f "${FILE}" ]; then
        info "Confirmed ${MESSAGE}"
        return 0
    fi
    touch "${FILE}"
    local SUCCESS="${?}"
    if [ "${SUCCESS}" -eq 0 ]; then
        info "Created ${MESSAGE}"
    else
        warn "Failed to create ${MESSAGE}"
    fi
    return "${SUCCESS}"
}

smart_link() {
    local GROUP="${1%/}"
    local IGNORE="${2%/}"
    local SRC="${3%/}"
    local DEST="${4%/}"
    local BACKUP="${5%/}"
    local FILE_NAME="${6##*/}"

    local SRC_FILE="${SRC}/${FILE_NAME}"
    local DEST_FILE="${DEST}/${FILE_NAME}"
    local FILE_STATUS="${DEST_FILE/${IGNORE}\//}"

    if [ ! -z "${GROUP}" ] && [ ! "${GROUP}" = "shared" ]; then
        FILE_STATUS="${FILE_STATUS} (${GROUP})"
    fi

    if [ -L "${DEST_FILE}" ]; then
        echo_status "${term_fg_green}" "         Linked" "${FILE_STATUS}"
        return 0

    elif [ -e "${DEST_FILE}" ]; then

        if truth "${PREVIEW}"; then
            local BACKUP_COLOUR="${term_fg_yellow}"
            if [ ! -d "${BACKUP}" ]; then
                BACKUP_COLOUR="${term_fg_red}"
            fi
            echo_status "${BACKUP_COLOUR}" "Backup Required" "${FILE_STATUS}"
        else
            if [ ! -d "${BACKUP}" ]; then
                echo_status "${term_fg_yellow}" "      No Backup" "${FILE_STATUS}"
                return 1
            fi
            backup_move "${DEST}" "${BACKUP}" "${FILE_NAME}" "${FILE_STATUS}" || return 1
        fi
    fi

    if truth "${PREVIEW}"; then
        local COLOUR="${term_fg_white}"
        if [ ! -d "${DEST}" ]; then
            COLOUR="${term_fg_yellow}"
        fi
        echo_status "${COLOUR}" "  Link Required" "${FILE_STATUS}"
        return 0
    fi
    if [ ! -d "${DEST}" ]; then
        mkdir -p "${DEST}"
        if [ ! -d "${DEST}" ]; then
            echo_status "${term_fg_red}" "    Link Failed" "${FILE_STATUS}"
            return 1
        fi
    fi

    if [ "${WINDOWS}" -eq 1 ]; then
        [ -d "${SRC_FILE}" ] && OPT="/D " || OPT=""

        local WIN_SRC_FILE="$(cygpath -w "${SRC_FILE}")"
        local WIN_DEST_FILE="$(cygpath -w "${DEST_FILE}")"
        local CMD_C="mklink ${OPT}${WIN_DEST_FILE} ${WIN_SRC_FILE}"

        # Windows link attempt
        cmd /C "\"${CMD_C}\"" > /dev/null 2>&1
    else
        # Unix link attempt
        ln -s "${SRC_FILE}" "${DEST_FILE}" > /dev/null 2>&1
    fi

    # must be next command after the link attempt to catch the process result
    if [ "${?}" -eq 0 ]; then
        echo_status "${term_fg_green}" "   Link Created" "${FILE_STATUS}"
        return 0
    else
        echo_status "${term_fg_red}" "    Link failed" "${FILE_STATUS}"
        return 1
    fi
}

doc_title() {
    local LINE=""
    echo -n "${term_bold}${term_fg_blue}"
    while read -r LINE; do
        echo "${LINE}"
    done;
    echo -n "${term_reset}"
}

dir_status() {
    local TITLE="${1}"
    local DIR="${2}"
    local EXTRA="${3}"

    local COLOUR=""
    if [ -z "${DIR}" ]; then
        COLOUR="${term_fg_yellow}"
        DIR="path not set"
    elif [ -d "${DIR}" ] || [ -L "${DIR}" ]; then
        COLOUR="${term_fg_green}"
    else
        COLOUR="${term_fg_red}"
    fi
    echo_status "${COLOUR}" "${TITLE}" "${DIR}${EXTRA}"
}

implode() {
    local IFS="${1}"; shift;
    echo "${*}"
}

echo_status() {
    local COLOUR="${1}"
    local TITLE="${2}"
    local MESSAGE="${3}"
    local TILDE="~"
    echo "${TITLE}: ${term_bold}${COLOUR}${MESSAGE//${TRUE_HOME_DIR}/${TILDE}}${term_reset}"
}

heading() {
    local MESSAGE="${1}"
    local TILDE="~"
    echo "${term_bold}${term_fg_green}:: ${term_fg_white}${MESSAGE//${TRUE_HOME_DIR}/${TILDE}}${term_reset}"
}

backup_move() {
    local SRC="${1%/}"
    local BACKUP="${2%/}"
    local FILE="${3##*/}"
    local FILE_STATUS="${4}"

    local DEST="${SRC/${HOME_DIR}/${BACKUP}}"
    local BACKUP_FILE="$(filename ${FILE})_${TIMESTAMP}$(extname ${FILE})"

    if [ ! -d "${DEST}" ]; then
        mkdir -p "${DEST}"
    fi
    mv "${SRC}/${FILE}" "${DEST}/${BACKUP_FILE}"

    local SUCCESS="${?}"
    if [ ${SUCCESS} -eq 0 ]; then
        echo_status "${term_fg_yellow}" " Backup Created" "${FILE_STATUS/${FILE}/${BACKUP_FILE}}"
    else
        echo_status "${term_fg_red}" "  Backup Failed" "${FILE_STATUS}"
    fi
    return "${SUCCESS}"
}

nested_dir() {
    local DIR="${1%/}"
    if [ ! -d "${DIR}" ]; then
        return 1
    fi
    DIR="${DIR//${DOTFILES_DIR}\//}"
    for NESTED in "${NESTED_DIRS[@]}"; do
        if [ "${DIR}" = "${NESTED}" ]; then
            return 0
        fi
    done
    return 1
}

ensure_nested_dir() {
    local GROUP="${1}"
    local DIR="${2%/}"
    local DIR_REF="${DIR//${DOTFILES_DIR}\//}"

    if [ ! -d "${DIR}" ]; then
        mkdir -p "${DIR}" || return 1
    fi

    if ! nested_dir "${DIR}"; then
        echo "${DIR_REF}" >> "${NESTING_FILE}" || return 1
        update_filesystem_variables
    fi
    return 0
}

main_title() {
    doc_title << 'EOF'
         __      __  _____ __
    ____/ /___  / /_/ __(_) /__
   / __  / __ \/ __/ /_/ / / _ \
  / /_/ / /_/ / /_/ __/ / /  __/
  \__,_/\____/\__/_/ /_/_/\___/

EOF
}

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
    VERSION="1.6.1"
    HELP=0
    if ! truth "${PREVIEW}";  then
        PREVIEW=0
    fi
    local UNAME="$(uname)"
    LINUX=0
    WINDOWS=0
    OSX=0
    if [ "${UNAME}" = "Linux" ]; then
        LINUX=1
    elif [ "${UNAME}" = "Darwin" ]; then
        OSX=1
    elif [[ "${UNAME}" =~ ^(MINGW|MSYS).*$ ]]; then
        WINDOWS=1
    fi
    UNIX_HOME="~"
    WIN_HOME=""
    if [ "${WINDOWS}" -eq 1 ] && [ -n "${HOMEDRIVE}" ] && [ -n "${HOMEPATH}" ]; then
        WIN_HOME="$(echo "${HOMEDRIVE}${HOMEPATH}" | sed 's|\\|/|g')"
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
    SYNC_EXCLUDE=(".git" ".gitignore" ".DS_Store")
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
    if truth "${OSX}" && [ -d "${DOTFILES_DIR}/osx" ]; then
        DOTFILE_GROUPS+=("osx")
    fi
    if truth "${LINUX}" && [ -d "${DOTFILES_DIR}/linux" ]; then
        DOTFILE_GROUPS+=("linux")
    fi
    if [ -d "${DOTFILES_DIR}/shared" ]; then
        DOTFILE_GROUPS+=("shared")
    fi
    NESTED_DIRS=()
    if [ -f "${NESTING_FILE}" ]; then
        local LINE=""
        while read LINE; do
            NESTED_DIRS+=("${LINE//[$'\t\r\n ']}")
        done < "${NESTING_FILE}"
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
    sync
}
