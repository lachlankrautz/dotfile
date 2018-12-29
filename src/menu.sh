#!/usr/bin/env bash

# Empty call
dotfile_() {
    usage
}

# Bad call
dotfile_call_() {
    usage
    exit 1
}

dotfile_option_v() {
    dotfile_option_version
}
dotfile_option_version() {
    echo "Version ${term_fg_yellow}${VERSION}${term_reset}"
}

dotfile_option_h() {
    dotfile_option_help "${@}"
}
dotfile_option_help() {
    HELP=1
    dispatch dotfile "${@}"
}

dotfile_option_p() {
    dotfile_option_preview "${@}"
}
dotfile_option_preview() {
    PREVIEW=1
    dispatch dotfile "$@"
}
