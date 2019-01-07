#!/usr/bin/env bash
# shellcheck disable=SC2154

# Empty call
dotfile_() {
    usage
}

# Bad call
dotfile_call_() {
    usage
    return 1
}

dotfile_option_v() {
    dotfile_option_version
}
dotfile_option_version() {
    echo "Version ${term_fg_yellow}2.0.0${term_reset}"
}

dotfile_option_h() {
    dotfile_option_help "${@}"
}
dotfile_option_help() {
    export HELP=1
    dispatch dotfile "${@}"
}

dotfile_option_p() {
    dotfile_option_preview "${@}"
}
dotfile_option_preview() {
    export PREVIEW=1
    dispatch dotfile "$@"
}
