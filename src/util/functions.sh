#!/usr/bin/env bash

link() {
    echo "linking ${1} to ${2}"
}

doc_title() {
    echo -n "${term_bold}${term_fg_blue}"
    while read -r LINE; do
        echo ${LINE}
    done;
    echo -n "${term_reset}"
}
