#!/usr/bin/env bash

HELP=0
WINDOWS=0
PROJECT_DIR=$(readlink -f ${BASH_SOURCE[0]%/*}"/../../")
CONFIG_DEFAULT=${PROJECT_DIR}/config/default.ini
CONFIG_LOCAL=${PROJECT_DIR}/config/local.ini

if [ ! -f ${CONFIG_LOCAL} ]; then
    cat << EOF >> ${CONFIG_LOCAL}

# Local config (not in version control)
# Uncomment to override defaults

# DOTFILE_DIR = "dotfile_repo"
EOF
fi

# source bash-ini-parser || read_ini.sh

# ${CONFIG_DEFAULT}
# ${CONFIG_LOCAL}
