#!/usr/bin/env bash

link() {
    echo "linking ${1} to ${2}"
}

heredoc_message() {
    # check for last char \ bug
    while read -r line; do var+=$line; done;
}
