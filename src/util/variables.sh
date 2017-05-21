#!/usr/bin/env bash

VERSION=1.0
HELP=0
WINDOWS=0
CONFIG_DEFAULT=${PATH_BASE}/config/default.ini
CONFIG_LOCAL=${PATH_BASE}/config/local.ini

if [ ! -f ${CONFIG_DEFAULT} ]; then
    die "Missing config file - ${CONFIG_DEFAULT}"
fi
if [ ! -f ${CONFIG_LOCAL} ]; then
    cat << EOF >> ${CONFIG_LOCAL}
; Local config (not in version control)
; Uncomment to override defaults

[repo]
; set local config loaded to remove safety
local_config_loaded=
; dotfile_repo=dotfile_store
EOF
fi
cfg_parser ${CONFIG_DEFAULT}
cfg_section_repo
cfg_parser ${CONFIG_LOCAL}
cfg_section_repo
if [ -z ${default_config_loaded} ]; then
    die "Invalid config - ${CONFIG_DEFAULT}"
fi
if [ -z ${local_config_loaded} ]; then
    die "Invalid config - ${CONFIG_LOCAL}"
fi
