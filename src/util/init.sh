#!/usr/bin/env bash

PATH_BASE=$(readlink -f ${BASH_SOURCE[0]%/*}"/../../")

load_lib() {
    # prepare
    PATH_TMP=$(pwd)
    LIB_DIR=${PATH_BASE}/lib/${1%/*}
    LIB_FILE=${1##*/}

    # do
    cd ${LIB_DIR}
    source ${LIB_FILE}
    cd ${PATH_TMP}

    #cleanup
    unset PATH_TMP
    unset LIB_DIR
    unset LIB_FILE
}

load_lib "bashful/bin/bashful"
load_lib "workshop/lib/workshop/dispatch.sh"
load_lib "bash-ini-parser/bash-ini-parser"

source "${PATH_BASE}/src/util/variables.sh"
source "${PATH_BASE}/src/util/functions.sh"
