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
  dotfile [options] [command] [args]

${term_fg_yellow}Options:${term_reset}
  ${term_fg_green}-h, --help${term_reset}                   Display usage
  ${term_fg_green}-v, --version${term_reset}                Display version

${term_fg_yellow}Commands:${term_reset}
  ${term_fg_green}sync${term_reset}                         Sync repo groups to home
  ${term_fg_green}status${term_reset}                       Demo sync without making changes
  ${term_fg_green}import${term_reset} [<pattern>] [<group>] Import home to repo group (default "shared")

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
        WRITABLE=1
        run_command "sync"
    else
        dispatch dotfile "$@"
    fi
}
dotfile_command_status() {
    if [ ${HELP} = 0 ]; then
        run_command "sync"
    else
        dispatch dotfile "$@"
    fi
}
dotfile_command_import() {
    if [ ${HELP} = 0 ]; then
        run_command "import" "$@"
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
