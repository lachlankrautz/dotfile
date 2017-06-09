#!/usr/bin/env bash

title_clean() {
    doc_title << 'EOF'
          __
    _____/ /__  ____ _____
   / ___/ / _ \/ __ `/ __ \
  / /__/ /  __/ /_/ / / / /
  \___/_/\___/\__,_/_/ /_/

EOF
}

command_clean() {
    title_clean
    clean_home
    if truth "${sync_root}"; then
        sudo_command clean_home
    fi
}

clean_home() {
    local DIR="${HOME_DIR}"
    if truth "${IS_ROOT}"; then
        DIR="/root"
    fi
    heading "Scanning ${DIR}"

    find "${DIR}" -type l -exec \
        ${PATH_BASE}/bin/clean_link "${PATH_BASE}" "${PREVIEW}" "{}" "${DOTFILES_DIR}" \;

    echo ""
    return 0
}
