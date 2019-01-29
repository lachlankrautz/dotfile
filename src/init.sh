#!/usr/bin/env bash
# shellcheck disable=SC1090

if [ "${DEBUG-0}" -gt 1 ]; then
    set -x
fi

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
source_files_in_dir "src/command" \
    "docker.sh" \
    "export.sh" \
    "import.sh" \
    "install.sh" \
    "scp.sh" \
    "sync.sh" \
    "update.sh"

load_global_variables || exit 1
