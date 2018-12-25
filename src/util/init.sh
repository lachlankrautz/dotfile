#!/usr/bin/env bash

if [ "${DEBUG}" -eq 1 ]; then
    set -x
    PS4='+ $(date "+%s.%N ($LINENO) ")'
fi

source_files_in_dir() {
    local PATH_TMP="$(pwd)"
    local LIB_DIR="${PATH_BASE}/${1}"
    shift

    cd "${LIB_DIR}"
    for LIB_FILE in "${@}"; do
        source "${LIB_FILE}"
    done
    cd "${PATH_TMP}"
}

# word split on newline
IFS=$'\n'
source_files_in_dir "lib/bashful" \
    "bashful-execute" \
    "bashful-files" \
    "bashful-input" \
    "bashful-messages" \
    "bashful-modes" \
    "bashful-terminfo" \
    "bashful-utils"
source_files_in_dir "lib/workshop" "dispatch.sh"
source_files_in_dir "lib/bash-ini-parser" "bash-ini-parser"
source_files_in_dir "src/util" "functions.sh"
source_files_in_dir "src" "clean.sh" "import.sh" "push.sh" "sync.sh"

load_global_variables
