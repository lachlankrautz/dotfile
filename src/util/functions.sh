#!/usr/bin/env bash

smart_link() {
    echo "1: ${1}"
    echo "2: ${2}"
    # exit
    if [ ${WINDOWS} -eq 1 ]; then
        # need windows path to home
        local CMD_C="mklink ${2} ${1}"
        echo "cmd /C ${CMD_C}"
        cmd /C "${CMD_C}"
    else
        ln -s ${1} ${2}
    fi
    if [ $? -eq 0 ]; then
        info "Linked ${1} to ${2}"
    else
        die "Failed to link ${1} to ${2}"
    fi
}

doc_title() {
    echo -n "${term_bold}${term_fg_blue}"
    while read -r LINE; do
        echo ${LINE}
    done;
    echo -n "${term_reset}"
}
