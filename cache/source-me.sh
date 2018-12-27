#!/usr/bin/env bash

DOTFILE_BIN_DIR="$(dirname ${BASH_SOURCE})"
PATH_BASE="$(dirname "${DOTFILE_BIN_DIR}")"

set -a
echo "Caching terminfo"
source "${PATH_BASE}/lib/bashful/bashful-terminfo"
set +a
