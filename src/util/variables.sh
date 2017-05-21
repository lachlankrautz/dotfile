#!/usr/bin/env bash

VERSION=1.0
HELP=0
[[ ${OS} =~ .*indows.* ]] && WINDOWS=1 || WINDOWS=0
CONFIG_DEFAULT=${PATH_BASE}/config/default.ini
CONFIG_LOCAL=${PATH_BASE}/config/local.ini

[ -f ${CONFIG_DEFAULT} ] || die "Missing config file - ${CONFIG_DEFAULT}"
[ -f ${CONFIG_LOCAL} ] || cat << EOF >> ${CONFIG_LOCAL}
;;; Local config - not in version control

[general]

;;; safety to ensure config has been checked by user
local_config_loaded=0

;;; dir to sync from
;;; absolute path or relative to this project
; dotfiles_dir=~/dotfiles

;;; home dir to sync to
; home_dir=~/

;;; backup dir for displaced home dotfiles
; backup_dir=~/dotfiles_bak

;;; also sync dotfiles to /root
; sync_to_root=0

;;; backup dir for displaced root dotfiles
; root_backup_dir=/root/dotfiles_bak
EOF

cfg_parser ${CONFIG_DEFAULT}
cfg_section_general
truth ${default_config_loaded} || die "Invalid config - ${CONFIG_DEFAULT}"

cfg_parser ${CONFIG_LOCAL}
cfg_section_general
truth ${local_config_loaded} || die "Invalid config - ${CONFIG_LOCAL}"
