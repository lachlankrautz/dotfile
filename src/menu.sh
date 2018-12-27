#!/usr/bin/env bash

dotfile_option_v() {
    dotfile_option_version
}

dotfile_option_version() {
    echo "Version ${term_fg_yellow}${VERSION}${term_reset}"
}

dotfile_option_h() {
    HELP=1
    dispatch dotfile "$@"
}

dotfile_option_help() {
    HELP=1
    dispatch dotfile "$@"
}

dotfile_option_p() {
    PREVIEW=1
    dispatch dotfile "$@"
}

dotfile_option_preview() {
    PREVIEW=1
    dispatch dotfile "$@"
}

dotfile_command_clean() {
    if [ ${HELP} = 0 ]; then
        command_clean
    else
        dispatch dotfile "$@"
    fi
}

dotfile_command_config() {
    command_config_sync "${@}"
}

dotfile_command_sync() {
    if [ ${HELP} = 0 ]; then
        command_sync
    else
        dispatch dotfile "$@"
    fi
}

dotfile_command_import() {
    if [ ${HELP} = 0 ]; then
        command_import "$@"
    else
        dispatch dotfile "$@"
    fi
}

dotfile_command_export() {
    if [ ${HELP} = 0 ]; then
        command_export "$@"
    else
        dispatch dotfile "$@"
    fi
}

dotfile_command_remote() {
    if [ ${HELP} = 0 ]; then
        command_remote "$@"
        echo
    else
        dispatch dotfile "$@"
    fi
}

dotfile_command_update() {
    if [ ${HELP} = 0 ]; then
        command_update "$@"
        echo
    else
        dispatch dotfile "$@"
    fi
}

dotfile_call_() {
    BAD_CALL=1
    usage
    exit 1
}

dotfile_() {
    usage
}

ensure_not_root
dispatch dotfile "$@"
exit 0
