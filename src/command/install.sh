#!/usr/bin/env bash

if [ ${HELP} = 1 ]; then
    cat << EOF

Install help

EOF
    exit
fi

# link "foo" "bar"

echo "dir: "${PROJECT_DIR%/*}/${DOTFILE_DIR}
