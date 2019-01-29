#!/usr/bin/env bash

title_install() {
    doc_title << 'EOF'
 // install //
EOF
    return 0
}

dotfile_command_install() {
    title_install

    ${SUDO_COMMAND} create_link "${PATH_BASE}/bin/dotfile" /usr/local/bin/dotfile || return 1
}
