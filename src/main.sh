#!/usr/bin/env bash

usage() {
    doc_title << 'EOF'
         __      __  _____ __
    ____/ /___  / /_/ __(_) /__
   / __  / __ \/ __/ /_/ / / _ \
  / /_/ / /_/ / /_/ __/ / /  __/
  \__,_/\____/\__/_/ /_/_/\___/

EOF
    cat << EOF
${term_fg_yellow}Usage:${term_reset}
  dotfile [options] [command]

${term_fg_yellow}Options:${term_reset}
  ${term_fg_green}-h, --help${term_reset}    Display usage
  ${term_fg_green}-v, --version${term_reset} Display version

${term_fg_yellow}Commands:${term_reset}
  ${term_fg_green}sync${term_reset}          Sync dotfiles to home dir

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
dotfile_command_sync() {
    if [ ${HELP} = 0 ]; then
        source ${PATH_BASE}/src/command/sync.sh
    else
        dispatch dotfile "$@"
    fi
}
dotfile_call_() {
    BAD_CALL=1
    usage
    exit
}
dotfile_() {
    usage
}
dispatch dotfile "$@"
