#!/usr/bin/env bash

title_update() {
    doc_title << 'EOF'
                     __      __
    __  ______  ____/ /___ _/ /____
   / / / / __ \/ __  / __ `/ __/ _ \
  / /_/ / /_/ / /_/ / /_/ / /_/  __/
  \__,_/ .___/\__,_/\__,_/\__/\___/
      /_/

EOF
    return 0
}

command_update() {
    title_update

    if ! dotfile_git diff-index --quiet HEAD --; then
        info "Local config changes detected"
        echo

        dotfile_git status
        echo

        question -p "Stage and commit changes?" -d "yes" || return 1
        dotfile_git commit -p || return 1
    fi

    info "Updating ${DOTFILES_REPO}"
    dotfile_git pull --rebase
    dotfile_git push
}
