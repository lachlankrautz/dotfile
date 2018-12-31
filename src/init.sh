#!/usr/bin/env bash

if [ "${DEBUG-0}" -gt 1 ]; then
    set -x
    PS4='+ $(date "+%s.%N ($LINENO) ")'
fi

source_files_in_dir() {
    local PATH_TMP="$(pwd)"
    local LIB_DIR="${PATH_BASE}/${1}"
    shift

    cd "${LIB_DIR}"
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
    cd "${PATH_TMP}"
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
    "import.sh" \
    "export.sh" \
    "remote.sh" \
    "sync.sh" \
    "update.sh"

load_global_variables || exit 1
