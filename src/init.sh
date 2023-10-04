#!/usr/bin/env bash
# shellcheck disable=SC1090
# shellcheck disable=SC2154

# Try to only use in subshells
cdd() {
    cd "${1}" || die "Unable to cd to ${1}"
}

# shellcheck disable=SC2034
load_global_variables() {
    HELP="${HELP-0}"
    PREVIEW="${PREVIEW-0}"
    ACTIVE_GROUP=shared

    # Platform
    local UNAME
    UNAME="$(uname -a)"
    local LINUX=0
    local LINUX_LAPTOP=0
    local OSX=0
    MSYS=0
    local WSL=0
    local WINDOWS=0
    if [[ ${UNAME} =~ ^Linux.*$ ]]; then
        LINUX=1
        # laptop-ish types:
        # - 8 portable
        # - 9 laptop
        # - 10 notebook
        # - 11 handheld
        # - 14 sub notebook
        # - 30 tablet
        if [[ $(cat /sys/class/dmi/id/chassis_type) =~ (8|9|10|11|14|30) ]]; then
            LINUX_LAPTOP=1
        fi
    fi
    if [[ ${UNAME} =~ ^Darwin.*$ ]]; then
        OSX=1
    fi
    if [[ ${UNAME} =~ ^(MINGW|MSYS).*$ ]]; then
        MSYS=1
        WINDOWS=1
    fi
    if [[ ${UNAME} =~ ^.*Microsoft.*$ ]]; then
        WSL=1
        WINDOWS=1
    fi

    # Home dir
    HOME_DIR=~
    TRUE_HOME_DIR="${TRUE_HOME_DIR-${HOME_DIR}}"
    [ "${LINUX}" -eq 1 ] && [ "${EUID}" -eq 0 ] && IS_ROOT=1 || IS_ROOT=0

    # Depends on loaded config
    ensure_config || return 1
    DOTFILE_MARKER=".dotfilemarker"
    DOTFILES_DIR="${config_dir/${HOME_DIR}\//${TRUE_HOME_DIR}/}"
    SYNC_EXCLUDE_LIST=(".git" ".gitignore" ".DS_Store" "${DOTFILE_MARKER}")
    [ "${IS_ROOT}" -eq 0 ] \
        && BACKUP_DIR="${TRUE_HOME_DIR}/.config/dotfile/backup" \
        || BACKUP_DIR="${TRUE_HOME_DIR}/.config/dotfile/backup_root"
    DOTFILES_REPO="${config_repo}"
    DOTFILE_GROUP_LIST=()

    # Order of dotfile groups, higher overrides lower
    [ -n "${custom_group}" ] && DOTFILE_GROUP_LIST+=("${custom_group}")
    [ "${MSYS}" -eq 1 ] && DOTFILE_GROUP_LIST+=("msys")
    [ "${WSL}" -eq 1 ] && DOTFILE_GROUP_LIST+=("wsl")
    [ "${WINDOWS}" -eq 1 ] && DOTFILE_GROUP_LIST+=("windows")
    [ "${OSX}" -eq 1 ] && DOTFILE_GROUP_LIST+=("darwin")
    [ "${IS_ROOT}" -eq 1 ] &&  DOTFILE_GROUP_LIST+=("root")
    [ "${LINUX_LAPTOP}" -eq 1 ] && DOTFILE_GROUP_LIST+=("linux_laptop")
    [ "${LINUX}" -eq 1 ] && DOTFILE_GROUP_LIST+=("linux")
    DOTFILE_GROUP_LIST+=("shared")

    local DOTFILE_GROUP
    for DOTFILE_GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        ensure_dir "${DOTFILES_DIR}/${DOTFILE_GROUP}" || return 1
        ensure_file "${DOTFILES_DIR}/${DOTFILE_GROUP}/${DOTFILE_MARKER}" || return 1
    done
}

source_files_in_dir() {
    local LIB_FILE
    cdd "${PATH_BASE}/${1}"
    shift

    for LIB_FILE in "${@}"; do
        source "${LIB_FILE}"
    done
    cdd - > /dev/null
}

source_files_in_dir "lib/bashful" \
    bashful-execute \
    bashful-files \
    bashful-input \
    bashful-messages \
    bashful-modes \
    bashful-terminfo \
    bashful-utils

source "${PATH_BASE}/lib/workshop/dispatch.sh"
source "${PATH_BASE}/lib/bash-ini-parser/bash-ini-parser"
source "${PATH_BASE}/src/functions.sh"

load_global_variables || exit 1
