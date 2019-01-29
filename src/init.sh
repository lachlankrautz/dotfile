#!/usr/bin/env bash
# shellcheck disable=SC1090
# shellcheck disable=SC2154

if [ "${DEBUG-0}" -gt 1 ]; then
    set -x
fi

# shellcheck disable=SC2034
load_global_variables() {
    HELP="${HELP-0}"
    PREVIEW="${PREVIEW-0}"
    DEBUG="${DEBUG-0}"

    # Platform
    local UNAME
    UNAME="$(uname -a)"
    local LINUX=0
    local OSX=0
    MSYS=0
    local WSL=0
    SUDO_COMMAND=sudo
    if [[ ${UNAME} =~ ^Linux.*$ ]]; then
        LINUX=1
    fi
    if [[ ${UNAME} = ^Darwin.*$ ]]; then
        OSX=1
    fi
    if [[ ${UNAME} =~ ^(MINGW|MSYS).*$ ]]; then
        MSYS=1
        SUDO_COMMAND=
    fi
    if [[ ${UNAME} =~ ^.*Microsoft.*$ ]]; then
        WSL=1
    fi

    # Home dir
    HOME_DIR=~
    TRUE_HOME_DIR="${TRUE_HOME_DIR-${HOME_DIR}}"
    [ "${LINUX}" -eq 1 ] && [ "${EUID}" -eq 0 ] && IS_ROOT=1 || IS_ROOT=0

    # Depends on loaded config
    ensure_config || return 1
    DOTFILE_MARKER=".dotfilemarker"
    DOTFILES_DIR="${config_dir/${HOME_DIR}\//${TRUE_HOME_DIR}/}"
    BACKUP_DIR="${TRUE_HOME_DIR}/.config/dotfile/backup"
    ROOT_BACKUP_DIR="${TRUE_HOME_DIR}/.config/dotfile/backup_root"
    SYNC_EXCLUDE_LIST=(".git" ".gitignore" ".DS_Store" "${DOTFILE_MARKER}")
    DOTFILES_REPO="${config_repo}"
    DOTFILE_GROUP_LIST=()

    # Order of dotfile overrides
    [ "${IS_ROOT}" -eq 1 ] &&  DOTFILE_GROUP_LIST+=("root")
    [ "${MSYS}" -eq 1 ] && DOTFILE_GROUP_LIST+=("msys")
    [ "${OSX}" -eq 1 ] && DOTFILE_GROUP_LIST+=("darwin")
    [ "${LINUX}" -eq 1 ] && DOTFILE_GROUP_LIST+=("linux")
    [ "${WSL}" -eq 1 ] && DOTFILE_GROUP_LIST+=("wsl")
    DOTFILE_GROUP_LIST+=("shared")

    local DOTFILE_GROUP
    for DOTFILE_GROUP in "${DOTFILE_GROUP_LIST[@]}"; do
        ensure_dir "${DOTFILES_DIR}/${DOTFILE_GROUP}" || return 1
        ensure_file "${DOTFILES_DIR}/${DOTFILE_GROUP}/${DOTFILE_MARKER}" || return 1
    done
}

source_files_in_dir() {
    local PATH_TMP="${PWD}"
    local LIB_DIR="${PATH_BASE}/${1}"
    shift

    cd "${LIB_DIR}" || exit 1
    for LIB_FILE in "${@}"; do
        if [ "${DEBUG-0}" -eq 1 ]; then
            echo "source ${LIB_FILE}"
            time source "${LIB_FILE}"
            echo
            echo
        else
            source "${LIB_FILE}"
        fi
    done
    cd "${PATH_TMP}" || exit 1
}

source_files_in_dir "lib/bashful" \
    bashful-execute \
    bashful-files \
    bashful-input \
    bashful-messages \
    bashful-modes \
    bashful-terminfo \
    bashful-utils

source_files_in_dir "lib/workshop" "dispatch.sh"
source_files_in_dir "lib/bash-ini-parser" "bash-ini-parser"
source_files_in_dir "src" "functions.sh"

load_global_variables || exit 1
