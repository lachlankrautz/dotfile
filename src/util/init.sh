#!/usr/bin/env bash

load_lib() {
    local PATH_TMP="$(pwd)"
    local LIB_DIR="${PATH_BASE}/lib/${1%/*}"
    local LIB_FILE="${1##*/}"

    cd "${LIB_DIR}"
    source "${LIB_FILE}"
    cd "${PATH_TMP}"
}

source_dir() {
    local PATH_COMMANDS="${1%/}"
    local FILE=""
    for FILE in "${PATH_COMMANDS}/"*; do
        source "${FILE}"
    done
}

# word split on newline
IFS=$'\n'
load_lib "bashful/bin/bashful"
load_lib "workshop/lib/workshop/dispatch.sh"
load_lib "bash-ini-parser/bash-ini-parser"
source "${PATH_BASE}/src/util/functions.sh"
source "${PATH_BASE}/src/util/variables.sh"
source_dir "${PATH_BASE}/src/command"
load_global_variables
