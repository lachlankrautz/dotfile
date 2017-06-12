#!/usr/bin/env bash

usage() {
    main_title
    cat << EOF
${term_fg_yellow}Usage:${term_reset}
  dotfile [options] [command] [args]

${term_fg_yellow}Options:${term_reset}
  ${term_fg_green}-h, --help${term_reset}                   Display usage
  ${term_fg_green}-v, --version${term_reset}                Display version
  ${term_fg_green}-p, --preview${term_reset}                Preview changes

${term_fg_yellow}Commands:${term_reset}
  ${term_fg_green}sync${term_reset}                         Sync repo groups to home
  ${term_fg_green}import${term_reset} [<pattern>] [<group>] Import home to repo group (default "shared")
  ${term_fg_green}push${term_reset}   [user@host]           Push dotfile and config to remote server
  ${term_fg_green}clean${term_reset}                        Remove broken repo links

EOF
}

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

dotfile_command_push() {
    if [ ${HELP} = 0 ]; then
        command_push "$@"
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
