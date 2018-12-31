#!/usr/bin/env bash

# Dotfile dependencies can take a while to load (especially with msys2)
# Source this file to cache the slower portions
#
# Add to .bashrc so dotfile runs faster
#
# ```bash
# source dotfile/cache/source-me.sh
# ```

DOTFILE_BIN_DIR="$(dirname ${BASH_SOURCE})"
PATH_BASE="$(dirname "${DOTFILE_BIN_DIR}")"

set -a
echo "Caching terminfo"
source "${PATH_BASE}/lib/bashful/bashful-terminfo"
set +a
