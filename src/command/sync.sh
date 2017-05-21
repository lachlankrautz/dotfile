#!/usr/bin/env bash

doc_title << 'EOF'
     _______  ______  _____
    / ___/ / / / __ \/ ___/
   (__  ) /_/ / / / / /__
  /____/\__, /_/ /_/\___/
       /____/

EOF

if [ ! -d ${dotfiles_dir} ]; then
    mkdir ${dotfiles_dir} || die "Unable to create dotfiles dir: ${dotfiles_dir}"
    info "Creating dotfiles dir: ${dotfiles_dir}"
fi

sync() {
    info "Syncing ${1} -> ${2}"
    [ -d ${1} ] || die "Missing src dir: ${1}"
    [ -d ${2} ] || die "Missing dest dir: ${2}"

    local SRC=${1%/}
    local DEST=${2%/}

    smart_link ${SRC}/foo ${DEST}/foo
}

sync ${dotfiles_dir} ${home_dir}
truth ${sync_to_root} && sync ${dotfiles_dir} /root

echo
